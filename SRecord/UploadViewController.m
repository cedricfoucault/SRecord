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
#import "SRAlertViewDelegate.h"
#import "SetCreationViewController.h"

@interface UploadViewController ()

@property (strong, nonatomic) NSMutableArray *recordingsToUpload;
@property (strong, nonatomic) NSMutableArray *tracksUploaded;
@property (nonatomic) NSUInteger uploadCount;
@property (nonatomic) NSUInteger uploadTotal;
@property (strong, nonatomic) SRAlertViewDelegate *alertDelegate;

- (void)uploadWhenLoggedIn;
- (void)startUploadWithCompletionHandler:(void (^)())handler;
- (void)uploadRecordingsWithCompletionHandler:(void (^)())handler;
- (void)uploadRecording:(RecordingHandler *)rec doNext:(void (^)(NSString *trackID))trackHandler;
- (void)cancel;

@end

@implementation UploadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tracksUploaded = [[NSMutableArray alloc] init];
        self.recordingsToUpload = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        self.tracksUploaded = [[NSMutableArray alloc] init];
        self.recordingsToUpload = [[NSMutableArray alloc] init];
    }
    return self;
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
    [self uploadWhenLoggedIn];
}


- (void)uploadWhenLoggedIn {
    static void (^doWhenLoggedIn)() = nil;
    if (doWhenLoggedIn == nil) {
        doWhenLoggedIn = ^() {
            // upload the recordings
            [self startUploadWithCompletionHandler:^() {
                // inform progress
                [SVProgressHUD showSuccessWithStatus:@"Uploaded"];
                // create a SoundCloud set for the new recordings
                [self performSegueWithIdentifier:@"CreateSetSegue" sender:self];
            }];
        };
    }
    // login to soundcloud if necessary
    if (![SCConnectionManager isLoggedIn]) {
        static void (^cancelHandler)() = nil;
        if (!cancelHandler) {
            cancelHandler = ^() {
                [self cancel];
            };
        }
        
        [SCConnectionManager presentLoginViewControllerWithPresenter:self
                                                         doOnSuccess:doWhenLoggedIn
                                                          doOnCancel:cancelHandler];
    } else {
        doWhenLoggedIn();
    }
}

- (void)startUploadWithCompletionHandler:(void (^)())handler {
    // reset the tracksUploaded array
    [self.tracksUploaded removeAllObjects];
    // init the recordings to upload
    [self.recordingsToUpload setArray:self.recordings];
    // upload recording by recording
    self.uploadCount = 0;
    self.uploadTotal = [self.recordingsToUpload count];
    [SVProgressHUD showProgress:0.0
                         status:[NSString stringWithFormat:@"Uploading %d of %d", self.uploadCount + 1, self.uploadTotal]
                       maskType:SVProgressHUDMaskTypeBlack];
    [self uploadRecordingsWithCompletionHandler:handler];
}

- (void)uploadRecordingsWithCompletionHandler:(void (^)())handler {
    // test if no more recording to upload
    if ([self.recordingsToUpload count] == 0) {
        // done
        handler();
    } else {
        // get the next recording to upload
        RecordingHandler *rec = [self.recordingsToUpload objectAtIndex:0];
        // show progress
        CGFloat progress = (double)(self.uploadCount) / self.uploadTotal;
        NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", self.uploadCount + 1, self.uploadTotal];
        [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
        // upload the recording and recurse when done
        [self uploadRecording:rec doNext:^(NSString *trackID) {
            // remove uploaded recording from the list
            [self.recordingsToUpload removeObjectAtIndex:0];
            // increase counter
            self.uploadCount++;
            // add uploaded track ID to the array
            if (trackID) {
                [self.tracksUploaded addObject:trackID];
            }
            [self uploadRecordingsWithCompletionHandler:handler];
        }];
        
    }
}

- (void)uploadRecording:(RecordingHandler *)rec doNext:(void (^)(NSString *trackID))trackHandler {
    // set request parameters for the track to upload
    SCAccount *account = [SCSoundCloud account];
    BOOL private = YES;
    NSString *trackTitle = [NSString stringWithFormat:@"%@ S%04d", rec.transcript, rec.sessionNo];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                rec.fileURL, @"track[asset_data]",
                                trackTitle, @"track[title]",
                                (private) ? @"private" : @"public", @"track[sharing]", //a BOOL
                                @"recording", @"track[type]",
                                @"description", @"A sample recorded from session ",
                                //             sharingConnections, @"track[post_to][][id]", //array of id strings
                                nil];
    // init response handler
    static void (^responseHandler)(NSURLResponse *, NSData *, NSError *) = nil;
    if (responseHandler == nil) {
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
                            alertMsg = [SCConnectionManager alertGenericMsgWithError:error];
                            break;
                    }
                } else {
                    alertTitle = @"Upload failed";
                    alertMsg = [SCConnectionManager alertGenericMsgWithError:error];
                }
                static void (^alertViewHandler)(UIAlertView *, NSInteger) = nil;
                if (alertViewHandler == nil) {
                    alertViewHandler = ^(UIAlertView *alertView, NSInteger buttonIndex) {
                        if (buttonIndex == [alertView cancelButtonIndex]) {
                            // cancel
                            [self cancel];
                        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Skip this one"]) {
                            // do next
                            trackHandler(nil);
                        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Try again"]) {
                            // try to upload recording again
                            [self uploadRecording:rec doNext:trackHandler];
                        }
                    };
                }
                self.alertDelegate = [[SRAlertViewDelegate alloc] initWithHandler:alertViewHandler];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                                    message:alertMsg
                                                                   delegate:self.alertDelegate
                                                          cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:@"Skip this one", @"Try again", nil];
                [alertView show];
            } else {
                if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSLog(@"Expecting a NSURLHTTPResponse.");
                    // do next (no track ID)
                    trackHandler(nil);
                } else {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] < 300) {
                        // Ok, the upload succeed.
                        // Parse the response to get the created track ID.
                        NSDictionary *trackInfo = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        NSString *trackID = [NSString stringWithFormat:@"%@", [trackInfo valueForKey:@"id"]];
                        // do next
                        trackHandler(trackID);
                    }
                }
            }
        };
    }
    
    // send POST request to /tracks
    NSUInteger n = self.uploadCount;
    NSUInteger N = self.uploadTotal;
    [SCRequest performMethod:SCRequestMethodPOST
                  onResource:[NSURL URLWithString:@"https://api.soundcloud.com/tracks.json"]
             usingParameters:parameters
                 withAccount:account
      sendingProgressHandler:^(unsigned long long bytesSent, unsigned long long bytesTotal){
          CGFloat progress = (double)bytesSent / (bytesTotal * N) + (double)n / N;
          NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", n + 1, N];
          [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
      }
             responseHandler:responseHandler];
    
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    // handle alert displayed when an upload failed 
//    if (buttonIndex == [alertView cancelButtonIndex]) {
//        // cancel
//        [self cancel];
//    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Skip this one"]) {
//        // do next
//        trackHandler(nil);
//    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Try again"]) {
//        // try to upload recording again
//        RecordingHandler *rec = [self.recordingsToUpload objectAtIndex:0];
//        [self uploadRecording:rec doNext:^(NSString *trackID) {
//            // remove uploaded recording from the list
//            [self.recordingsToUpload removeObjectAtIndex:0];
//            // increase counter
//            self.uploadCount++;
//            // add uploaded track ID to the array
//            if (trackID) {
//                [self.tracksUploaded addObject:trackID];
//            }
//            [self uploadRecordingsWithCompletionHandler:handler];
//        }];
//    }
//}

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
    [self performSegueWithIdentifier:@"CancelSession" sender:self];
}

@end
