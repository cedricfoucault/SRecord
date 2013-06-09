//
//  UploadController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/8/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "UploadController.h"
#import "SCConnectionManager.h"
#import "RecordingHandler.h"
#import "ErrorHelper.h"
#import <SCAPI.h>
#import <SVProgressHUD.h>

@interface UploadController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableArray *tracksUploaded;
@property (strong, nonatomic) NSMutableArray *uploadsRemaining;
@property (copy, nonatomic) NSString *SCSetName;
@property (strong, nonatomic) RecordingHandler *currentUpload;
@property (nonatomic) NSUInteger currentNo; // counter for the uploads
@property (nonatomic) NSUInteger totalNo; // number of uploads to perform
@property (strong, nonatomic) void (^progressHandler)(unsigned long long bytesSent, unsigned long long bytesTotal);
@property (strong, nonatomic) void (^responseHandler)(NSURLResponse *response, NSData *responseData, NSError *error);

- (void)customInit;
- (void)resetUploadVariables;
- (void)uploadRemaining;
- (void)createSCSetForCurrentUpload;
- (RecordingHandler *)popUpload;
- (void)commitTrack:(NSString *)trackID;
- (void)setHandlersForCurrentUpload;
- (void)setHandlersForSetCreation;

@end

@implementation UploadController

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        [self customInit];
    }
    return self;
}

- (void)customInit {
    self.tracksUploaded = [[NSMutableArray alloc] init];
    self.uploadsRemaining = [[NSMutableArray alloc] init];
}

- (id)initWithDelegate:(UIViewController<UploadControllerDelegate> *)delegate {
    self = [self init];
    self.delegate = delegate;
    return self;
}

- (void)resetUploadVariables {
    // reset the tracksUploaded array
    [self.tracksUploaded removeAllObjects];
    // upload recording by recording
    self.currentNo = 0;
    self.totalNo = [self.uploadsRemaining count];
}

- (void)uploadTracksWithRecordings:(NSArray *)recordings SCSetName:(NSString *)name {
    // init the recordings to upload
    [self.uploadsRemaining setArray:recordings];
    self.SCSetName = name;
    // reset instance variables for the new uploading process
    [self resetUploadVariables];
    // login to soundcloud if necessary
    if (![SCConnectionManager isLoggedIn]) {
        // if login was successful, perform uploading
        void (^successHandler)();
        successHandler = ^() {
            [self uploadRemaining];
        };
        // if login was canceled, cancel uploading
        void (^cancelHandler)();
        cancelHandler = ^() {
            [SVProgressHUD showErrorWithStatus:@"Canceled"];
            [self.delegate didCancelUploading];
        };
        // present login view
        [SCConnectionManager presentLoginViewControllerWithPresenter:self.delegate
                                                         doOnSuccess:successHandler
                                                          doOnCancel:cancelHandler];
    } else {
        // if already logged in, perform uploading directly
        [self uploadRemaining];
    }
}

- (void)uploadRemaining {
    if ([self.uploadsRemaining count] != 0) {
        // pop next remaining upload
        self.currentUpload = [self popUpload];
        // increase counter
        self.currentNo++;
        // show progress
        CGFloat progress = (double)(self.currentNo - 1) / self.totalNo;
        NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", self.currentNo, self.totalNo];
        [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
        // perform the current upload and recurse when done
        [self uploadCurrentAndRemaining];
    } else {
        // done uploading tracks
        // create a SoundCloud set for the uploaded tracks
        [self createSCSetForCurrentUpload];
    }
}

- (void)createSCSetForCurrentUpload {
    // set progress handler for set creation
    [self setHandlersForSetCreation];
    // create the set
    [self createSCSetWithName:self.SCSetName tracks:self.tracksUploaded
              progressHandler:self.progressHandler
              responseHandler:self.responseHandler];
}

- (void)uploadCurrentAndRemaining {
    // set progress and response handlers for current track upload
    [self setHandlersForCurrentUpload];
    // perform the current upload
    [self uploadTrackWithRecording:self.currentUpload
                   progressHandler:self.progressHandler
                   responseHandler:self.responseHandler];
}


- (void)uploadTrackWithRecording:(RecordingHandler *)rec
             progressHandler:(void (^)(unsigned long long, unsigned long long))progressHandler
             responseHandler:(void (^)(NSURLResponse *, NSData *, NSError *))responseHandler {
    // set request parameters for the track to upload
    SCAccount *account = [SCSoundCloud account];
    static BOOL private = YES;
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                rec.fileURL, @"track[asset_data]",
                                rec.trackTitle, @"track[title]",
                                @"true", @"track[downloadable]",
                                @"wav", @"track[original_format]",
                                (private) ? @"private" : @"public", @"track[sharing]", //a BOOL
                                @"recording", @"track[type]",
                                @"description", rec.transcript,
                                nil];
    // send POST request to /tracks
    [SCRequest performMethod:SCRequestMethodPOST
                  onResource:[NSURL URLWithString:@"https://api.soundcloud.com/tracks.json"]
             usingParameters:parameters
                 withAccount:account
      sendingProgressHandler:progressHandler
             responseHandler:responseHandler];
}

- (void)createSCSetWithName:(NSString *)name tracks:(NSArray *)tracksID
            progressHandler:(void (^)(unsigned long long, unsigned long long))progressHandler
            responseHandler:(void (^)(NSURLResponse *, NSData *, NSError *))responseHandler {
    SCAccount *account = [SCSoundCloud account];
    static BOOL private = YES;
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                name, @"playlist[title]",
                                (private) ? @"private" : @"public", @"playlist[sharing]", //a BOOL
                                tracksID, @"playlist[tracks][][id]",
                                nil];
    // set POST request to /playlists
    [SCRequest performMethod:SCRequestMethodPOST
                  onResource:[NSURL URLWithString:@"https://api.soundcloud.com/playlists.json"]
             usingParameters:parameters
                 withAccount:account
      sendingProgressHandler:progressHandler
             responseHandler:responseHandler];
}

- (NSDictionary *)parseResponseData:(NSData *)data {
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}

- (void)setHandlersForCurrentUpload {
    // set progress handler for current upload
    __block UploadController *blockSelf = self;
    self.progressHandler = ^(unsigned long long bytesSent, unsigned long long bytesTotal) {
        CGFloat progress = (double)bytesSent / (bytesTotal * blockSelf.totalNo) + (double)(blockSelf.currentNo - 1) / blockSelf.totalNo;
        NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", blockSelf.currentNo, blockSelf.totalNo];
        [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
    };
    // set response handler for current upload
    self.responseHandler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSString *alertTitle = @"Upload failed";
            NSString *alertMsg;
            if ([[error domain] isEqualToString:NSURLErrorDomain]) {
                switch ([error code]) {
                    case NSURLErrorNotConnectedToInternet:
//                        alertTitle = @"No Internet Connection";
                        alertMsg = @"Cannot connect to the internet. Service may not be available.";
                        break;
                        
                    case NSURLErrorCannotConnectToHost:
//                        alertTitle = @"Host Unavailable";
                        alertMsg = @"Cannot connect to SoundCloud. Server may be down.";
                        break;
                        
                    default:
//                        alertTitle = @"Request failed";
                        alertMsg = [ErrorHelper genericMsgWithError:error];
                        break;
                }
            } else {
//                alertTitle = @"Upload failed";
                alertMsg = [ErrorHelper genericMsgWithError:error];
            }
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                                message:alertMsg
                                                               delegate:blockSelf
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Try again", @"Skip this one", nil];
            [alertView show];
        } else {
            if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSLog(@"Expecting a NSURLHTTPResponse.");
                // upload remaining
                [blockSelf uploadRemaining];
            } else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] < 300) {
                    // Ok, the upload succeed.
                    // Parse the response to get the created track ID.
                    NSDictionary *trackInfo = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSString *trackID = [NSString stringWithFormat:@"%@", [trackInfo valueForKey:@"id"]];
                    // commit track
                    [blockSelf commitTrack:trackID];
                    // upload remaining
                    [blockSelf uploadRemaining];
                }
            }
        }
    };
}

- (void)setHandlersForSetCreation {
    __block UploadController *blockSelf = self;
    // set progress handler
    self.progressHandler = ^(unsigned long long bytesSent, unsigned long long bytesTotal) {
        CGFloat progress = (double)bytesSent / bytesTotal;
        [SVProgressHUD showProgress:progress status:@"Creating set" maskType:SVProgressHUDMaskTypeBlack];
    };
    // set response handler for set creation
    self.responseHandler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSString *alertTitle = @"Set creation failed";
            NSString *alertMsg;
            if ([[error domain] isEqualToString:NSURLErrorDomain]) {
                switch ([error code]) {
                    case NSURLErrorNotConnectedToInternet:
//                        alertTitle = @"No Internet Connection";
                        alertMsg = @"Cannot connect to the internet. Service may not be available.";
                        break;
                        
                    case NSURLErrorCannotConnectToHost:
//                        alertTitle = @"Host Unavailable";
                        alertMsg = @"Cannot connect to SoundCloud. Server may be down.";
                        break;
                        
                    default:
//                        alertTitle = @"Request failed";
                        alertMsg = [ErrorHelper genericMsgWithError:error];
                        break;
                }
            } else {
//                alertTitle = @"Set creation failed";
                alertMsg = [ErrorHelper genericMsgWithError:error];
            }
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                                message:alertMsg
                                                               delegate:blockSelf
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Try again", @"Skip set creation", nil];
            [alertView show];
        } else {
            if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSLog(@"Expecting a NSURLHTTPResponse.");
                // inform that the request has succeeded
                [SVProgressHUD showSuccessWithStatus:@"Uploading done"];
                // uploading process done
                [blockSelf.delegate didFinishUploading];
            } else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] < 300) {
                    // inform that the set creation request has succeeded
                    [SVProgressHUD showSuccessWithStatus:@"Uploading done"];
                    // uploading process done
                    [blockSelf.delegate didFinishUploading];
                }
            }
        }
    };
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView title] isEqualToString:@"Upload failed"]) {
        // handle alert displayed when an upload failed
        if (buttonIndex == [alertView cancelButtonIndex]) {
            // cancel
            [SVProgressHUD showErrorWithStatus:@"Canceled"];
            [self.delegate didCancelUploading];
        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Skip this one"]) {
            // continue uploading skipping the current one
            [self uploadRemaining];
        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Try again"]) {
            // reset progress
            CGFloat progress = (double)(self.currentNo - 1) / self.totalNo;
            NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", self.currentNo, self.totalNo];
            [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
            // perform the current upload again
            [self uploadCurrentAndRemaining];
        }
    } else if ([[alertView title] isEqualToString:@"Set creation failed"]) {
        // handle alert displayed when the set creation step failed
        if (buttonIndex == [alertView cancelButtonIndex]) {
            // cancel
            [SVProgressHUD showErrorWithStatus:@"Canceled"];
            [self.delegate didCancelUploading];
        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Skip set creation"]) {
            // finish
            [SVProgressHUD dismiss];
            [self.delegate didFinishUploading];
        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Try again"]) {
            // reset progress
            [SVProgressHUD showProgress:0.0 status:@"Creating set" maskType:SVProgressHUDMaskTypeBlack];
            // perform the current upload again
            [self createSCSetForCurrentUpload];
        }
    }
}

- (RecordingHandler *)popUpload {
    // get next upload
    RecordingHandler *upload = [self.uploadsRemaining objectAtIndex:0];
    // remove it from the list
    [self.uploadsRemaining removeObjectAtIndex:0];
    return upload;
}

- (void)commitTrack:(NSString *)trackID {
    if (trackID) {
        [self.tracksUploaded addObject:trackID];
    }
}

@end
