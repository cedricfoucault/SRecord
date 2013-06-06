//
//  UploadViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/5/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "UploadViewController.h"
#import "RecordingHandler.h"
#import <SCUI.h>
#import "SCConnectionManager.h"
#import <SVProgressHUD.h>
#import "SetCreationViewController.h"
#import "ErrorHelper.h"

@interface UploadViewController ()

@property (strong, nonatomic) NSMutableArray *remainingUploads;
@property (strong, nonatomic) RecordingHandler *currentUpload;
@property (strong, nonatomic) NSMutableArray *tracksUploaded;
@property (nonatomic) NSUInteger uploadCount;
@property (nonatomic) NSUInteger uploadTotal;

- (void)customInit;
- (void)initUploading;
- (void)uploadRemaining;
- (void)uploadCurrentAndRemaining;
- (void)commitTrack:(NSString *)trackID;
- (RecordingHandler *)popUpload;
- (void)cancel;

@end

@implementation UploadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self customInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        [self customInit];
    }
    return self;
}

- (void)customInit {
    self.tracksUploaded = [[NSMutableArray alloc] init];
    self.remainingUploads = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)okButtonTapped:(id)sender {
    // login to soundcloud if necessary
    if (![SCConnectionManager isLoggedIn]) {
        // if login was successful, perform uploading
        void (^successHandler)();
        successHandler = ^() {
            [self initUploading];
            [self uploadRemaining];
        };
        // if login was canceled, cancel uploading
        void (^cancelHandler)();
        cancelHandler = ^() {
            [self cancel];
        };
        // present login view
        [SCConnectionManager presentLoginViewControllerWithPresenter:self doOnSuccess:successHandler doOnCancel:cancelHandler];
    } else {
        // if already logged in, perform uploading directly
        [self initUploading];
        [self uploadRemaining];
    }
}

- (void)initUploading {
    // reset the tracksUploaded array
    [self.tracksUploaded removeAllObjects];
    // init the recordings to upload
    [self.remainingUploads setArray:self.recordings];
    // upload recording by recording
    self.uploadCount = 0;
    self.uploadTotal = [self.remainingUploads count];
}

- (void)uploadRemaining {
    if ([self.remainingUploads count] != 0) {
        // pop next remaining upload
        self.currentUpload = [self popUpload];
        // increase counter
        self.uploadCount++;
        // show progress
        CGFloat progress = (double)(self.uploadCount - 1) / self.uploadTotal;
        NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", self.uploadCount, self.uploadTotal];
        [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
        // perform the current upload and recurse when done
        [self uploadCurrentAndRemaining];
    } else {
        // inform done uploading
        [SVProgressHUD showSuccessWithStatus:@"Uploaded"];
        // create a SoundCloud set for the new recordings
        [self performSegueWithIdentifier:@"CreateSetSegue" sender:self];
    }
}

- (void)uploadCurrentAndRemaining {
    // set request parameters for the track to upload
    SCAccount *account = [SCSoundCloud account];
    BOOL private = YES;
    NSString *trackTitle = [NSString stringWithFormat:@"%@ S%04d", self.currentUpload.transcript, self.currentUpload.sessionNo];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.currentUpload.fileURL, @"track[asset_data]",
                                trackTitle, @"track[title]",
                                (private) ? @"private" : @"public", @"track[sharing]", //a BOOL
                                @"recording", @"track[type]",
                                @"description", @"A sample recorded from session ",
                                nil];
    // init response handler
    void (^responseHandler)(NSURLResponse *, NSData *, NSError *);
    responseHandler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSString *alertTitle;
            NSString *alertMsg;
            if ([[error domain] isEqualToString:NSURLErrorDomain]) {
                switch ([error code]) {
                    case NSURLErrorNotConnectedToInternet:
                        alertTitle = @"No Internet Connection";
                        alertMsg = @"Cannot connect to the internet. Service may not be available.";
                        break;
                        
                    case NSURLErrorCannotConnectToHost:
                        alertTitle = @"Host Unavailable";
                        alertMsg = @"Cannot connect to SoundCloud. Server may be down.";
                        break;
                        
                    default:
                        alertTitle = @"Request failed";
                        alertMsg = [ErrorHelper genericMsgWithError:error];
                        break;
                }
            } else {
                alertTitle = @"Upload failed";
                alertMsg = [ErrorHelper genericMsgWithError:error];
            }
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                                message:alertMsg
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Skip this one", @"Try again", nil];
            [alertView show];
        } else {
            if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSLog(@"Expecting a NSURLHTTPResponse.");
                // upload remaining
                [self uploadRemaining];
            } else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] < 300) {
                    // Ok, the upload succeed.
                    // Parse the response to get the created track ID.
                    NSDictionary *trackInfo = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSString *trackID = [NSString stringWithFormat:@"%@", [trackInfo valueForKey:@"id"]];
                    // commit track
                    [self commitTrack:trackID];
                    // upload remaining
                    [self uploadRemaining];
                }
            }
        }
    };
    // init progress handler
    void (^progressHandler)(unsigned long long, unsigned long long);
    progressHandler = ^(unsigned long long bytesSent, unsigned long long bytesTotal){
        CGFloat progress = (double)bytesSent / (bytesTotal * self.uploadTotal) + (double)(self.uploadCount - 1) / self.uploadTotal;
        NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", self.uploadCount, self.uploadTotal];
        [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
    };
    // send POST request to /tracks
    [SCRequest performMethod:SCRequestMethodPOST
                  onResource:[NSURL URLWithString:@"https://api.soundcloud.com/tracks.json"]
             usingParameters:parameters
                 withAccount:account
      sendingProgressHandler:progressHandler
             responseHandler:responseHandler];
}

- (void)commitTrack:(NSString *)trackID {
    if (trackID) {
        [self.tracksUploaded addObject:trackID];
    }
}

- (RecordingHandler *)popUpload {
    // get next upload
    RecordingHandler *upload = [self.remainingUploads objectAtIndex:0];
    // remove it from the list
    [self.remainingUploads removeObjectAtIndex:0];
    return upload;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // handle alert displayed when an upload failed 
    if (buttonIndex == [alertView cancelButtonIndex]) {
        // cancel
        [self cancel];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Skip this one"]) {
        // continue uploading skipping the current one
        [self uploadRemaining];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Try again"]) {
        // reset progress
        CGFloat progress = (double)(self.uploadCount - 1) / self.uploadTotal;
        NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", self.uploadCount, self.uploadTotal];
        [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
        // perform the current upload again
        [self uploadCurrentAndRemaining];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CreateSetSegue"]) {
        // build default set title from current date
        static NSDateFormatter *dateFormatter = nil;
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        }
        // send the controller the tracks ID and default set title
        SetCreationViewController *setCreationController = [segue destinationViewController];
        setCreationController.tracksID = [NSArray arrayWithArray:self.tracksUploaded];
        setCreationController.defaultSetTitle = [dateFormatter stringFromDate:[NSDate date]];
    }
}

- (void)cancel {
    [self performSegueWithIdentifier:@"CancelUpload" sender:self];
}

@end
