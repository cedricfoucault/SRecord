//
//  SessionViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 5/27/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SessionViewController.h"
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioRecorder.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <stdlib.h>
#import "RecordingHandler.h"
#import <SoundCloudUI/SCUI.h>
#import "SRConstants.h"
#import <SVProgressHUD.h>
#import "SCConnectionManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SRAlertViewDelegate.h"
#import "UploadViewController.h"

@interface SessionViewController ()

@property (nonatomic) int fileCount;
//@property (strong, nonatomic) UIImage *startRecordIcon;
//@property (strong, nonatomic) UIImage *startRecordPressedIcon;
//@property (strong, nonatomic) UIImage *stopRecordIcon;
@property (strong, nonatomic) SRAlertViewDelegate *alertDelegate;

- (NSString *)popSentence;
- (NSURL *)newFileURL;
- (void)commitRecording;
- (void)uploadRecordingsWithEnumerator:(NSEnumerator *)enumerator
                             fileCount:(NSUInteger)n fileTotal:(NSUInteger)N
                      appendTracksIDTo:(NSMutableArray *)tracksID
                            doWhenDone:(void (^)(NSArray *))successHandler
                            doOnCancel:(void (^)())cancelHandler;
- (void)uploadRecording:(RecordingHandler *)rec
              fileCount:(NSUInteger)n fileTotal:(NSUInteger)N
                 doNext:(void (^)(NSString *))successHandler
             doOnCancel:(void (^)())cancelHandler;
- (void)cancel;
- (void)done;

@end

@implementation SessionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
//        self.startRecordIcon = [UIImage imageNamed:@"Record-Normal-icon.png"];
//        self.startRecordPressedIcon = [UIImage imageNamed:@"Record-Pressed-icon.png"];
//        self.stopRecordIcon = [UIImage imageNamed:@"stop-record-icon.png"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.recordingsDone = [[NSMutableArray alloc] init];
    [self nextState];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"UploadSegue"]) {
        UploadViewController *uploadController = [segue destinationViewController];
        uploadController.recordings = [NSArray arrayWithArray:self.recordingsDone];
    }
}

- (void)startNewSessionWithSentences:(NSArray *)sentences {
    // reset file count for this session
    self.fileCount = 0;
    self.recording = NO;
    self.sentencesRemaining = [NSMutableArray arrayWithArray:sentences];
    self.sessionNo = arc4random_uniform(9999); // generate a random session number of <= 4 digits
    // remove old recording files from temporary storage
    [self removeOldRecordings];
}

- (IBAction)handleTouchUpInside:(UIButton *)recButton {
//    recButton.layer.cornerRadius = 0.0;
//    recButton.layer.borderWidth = 1.0;
//    recButton.layer.hidden = NO;
//    recButton.layer.masksToBounds = YES;
    if (self.isRecording) {
        [self stopRecording];
        [self commitRecording];
        [self nextState];
//        [recButton setImage:self.startRecordIcon forState:UIControlStateNormal];
//        [recButton setImage:self.startRecordPressedIcon forState:UIControlStateHighlighted];
        [recButton setTitle:@"Record" forState:UIControlStateNormal];
        [recButton setTitle:@"Record" forState:UIControlStateHighlighted];
    } else {
        [self startRecording];
//        [recButton setImage:self.stopRecordIcon forState:UIControlStateNormal];
//        [recButton setImage:self.stopRecordIcon forState:UIControlStateHighlighted];
        [recButton setTitle:@"Stop" forState:UIControlStateNormal];
        [recButton setTitle:@"Stop" forState:UIControlStateHighlighted];
    }
}

- (IBAction)handleTouchDown:(UIButton *)recButton {
    if (self.isRecording) {
        // pause recording in order not to record the "tap" sound
        [self.soundRecorder pause];
    } else {
        
    }
}

- (IBAction)handleTouchUpOutside:(UIButton *)sender {
    if (self.isRecording) {
        // if we were recording, the recorder was paused when button was touched down
        // we have to resume it since the user decided not to click the button after all
        [self.soundRecorder record];
    }
}

- (IBAction)quitTapped:(UIButton *)sender {
    UIActionSheet *confirmActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                 destructiveButtonTitle:@"Abort Session"
                                                      otherButtonTitles:nil];
    NSLog(@"%d", [confirmActionSheet numberOfButtons]);
    [confirmActionSheet showFromRect:self.quitButton.frame inView:self.view animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [actionSheet cancelButtonIndex]) { // not cancel
        [self endSessionPrematurely];
    }
}

- (void)nextState {
    if ([self.sentencesRemaining count]) {
        self.currentRecording = [self prepareNewRecording];
        self.sentenceLabel.text = self.currentRecording.transcript;
    } else {
        [self endSession];
    }
}

- (void)startRecording {
    // alert current audio session that we are recording
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryRecord error: nil];
    // start the recorder
    [self.soundRecorder record];
    self.recording = YES;
}

- (void)stopRecording {
    // stop the recorder
    [self.soundRecorder stop];
    self.recording = NO;
    // release recorder
    self.soundRecorder = nil;
    // set session inactive
    [[AVAudioSession sharedInstance] setActive: NO error: nil];
}

- (void)commitRecording {
    [self.recordingsDone addObject: self.currentRecording];
}

- (void)endSession {
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Done!" message:@"The samples for this session have all been recorded. We will now upload the recordings to SoundCloud." delegate:self cancelButtonTitle:@"Don't Upload" otherButtonTitles:@"OK", nil];
//    [alert show];
    [SVProgressHUD showSuccessWithStatus:@"All done"];
    [self performSegueWithIdentifier:@"UploadSegue" sender:self];
    
}

- (void)endSessionPrematurely {
    if ([self.soundRecorder isRecording]) {
        [self stopRecording];
    }
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload before quitting"
//                                                    message:@"Do you want to upload the recording performed so far?"
//                                                   delegate:self
//                                          cancelButtonTitle:NSLocalizedString(@"No", @"")
//                                          otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
//    [alert show];
    [self performSegueWithIdentifier:@"UploadSegue" sender:self];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView cancelButtonIndex]) {
        [self cancel];
//        [self performSegueWithIdentifier:@"CancelSession" sender:self];
    } else {
        static void (^doWhenLoggedIn)() = nil;
        if (doWhenLoggedIn == nil) {
            doWhenLoggedIn = ^() {
                // upload the recordings
                [self uploadRecordingsWithCompletionHandler:^(NSArray *tracksID) {
                    // create a SoundCloud set for the new recordings
                    [self createSCSetWithTracks:tracksID completionHandler:^() {
                        // go back to main menu
                        [self done];
                    }];
                }];
            };
        }
        // login to soundcloud if necessary
        if (![SCConnectionManager isLoggedIn]) {
            void (^cancelHandler)() = ^() {
                // go back to main menu
//                [self performSegueWithIdentifier:@"CancelSession" sender:self];
                [self cancel];
            };
                 
            [SCConnectionManager presentLoginViewControllerWithPresenter:self
                                                             doOnSuccess:doWhenLoggedIn
                                                              doOnCancel:cancelHandler];
        } else {
            doWhenLoggedIn();
//            // upload the recordings
//            [self uploadRecordingsWithCompletionHandler:^(NSArray *tracksID) {
//                // create a SoundCloud set for the new recordings
//                [self createSCSetWithTracks:tracksID completionHandler:^() {
//                    // go back to main menu
//                    [SVProgressHUD showSuccessWithStatus:@"Uploaded"];
//                    [self done];
//                }];
//            }];
        }
    }
}

- (RecordingHandler *)prepareNewRecording {
    // init new recording handler
    NSURL *soundFileURL = [self newFileURL];
    NSString *sentence = [self popSentence];
    RecordingHandler *recordingHandler = [[RecordingHandler alloc] initWithFileURL:soundFileURL transcript:sentence sessionNo:self.sessionNo];
    // init audio session active
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
    // init recorder for upcoming recording
    NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNumber numberWithFloat: audioSession.sampleRate], AVSampleRateKey,
                                    [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                    [NSNumber numberWithInt: AVAudioQualityMax],
                                    AVEncoderAudioQualityKey,
                                    nil];
    self.soundRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings: recordSettings error:nil];
    self.soundRecorder.delegate = self;
    [self.soundRecorder prepareToRecord];
    return recordingHandler;
}

- (void)uploadRecordingsWithCompletionHandler:(void (^)(NSArray *))handler {
    NSLog(@"Start uploading");
    // upload recording by recording
    NSMutableArray *tracksID = [[NSMutableArray alloc] init];
    NSUInteger n = 1;
    NSUInteger N = [self.recordingsDone count];
    NSEnumerator *enumerator = [self.recordingsDone objectEnumerator];
    [SVProgressHUD showProgress:0.0 status:[NSString stringWithFormat:@"Uploading %d of %d", n, N] maskType:SVProgressHUDMaskTypeBlack];
    [self uploadRecordingsWithEnumerator:enumerator fileCount:n fileTotal:N
                        appendTracksIDTo:tracksID
                              doWhenDone:handler
                              doOnCancel:^() {
                                  [self cancel];
                              }];
}

- (void)createSCSetWithTracks:(NSArray *)tracksID completionHandler:(void (^)())handler {
    // build default set title from current date
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    NSString *defaultSetTitle = [dateFormatter stringFromDate:[NSDate date]];
    // show alert view to inform user of default name and optionally ask custom name
    static void (^setCreationAlertHandler)(UIAlertView *, NSInteger) = nil;
    if (setCreationAlertHandler == nil) {
        setCreationAlertHandler = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            // set request parameters for the new set
            NSString *title;
            if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput && [alertView textFieldAtIndex:0].text != nil) {
                title = [alertView textFieldAtIndex:0].text;
            } else {
                title = defaultSetTitle;
            }
            SCAccount *account = [SCSoundCloud account];
            BOOL private = YES;
            NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                        title, @"playlist[title]",
                                        (private) ? @"private" : @"public", @"playlist[sharing]", //a BOOL
                                        tracksID, @"playlist[tracks][][id]",
                                        nil];
            // init response handler
            static void (^responseHandler)(NSURLResponse *, NSData *, NSError *) = nil;
            if (responseHandler == nil) {
                responseHandler = ^(NSURLResponse *response, NSData *data, NSError *error) {
                    [SVProgressHUD dismiss];
                    if (error) {
                        // call the completion handler without handling the error
                        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                        handler();
                    } else { // success
                        // call the completion handler and inform that the request has suceeded
                        [SVProgressHUD showSuccessWithStatus:@"Set created"];
                        handler();
                    }
                };
            }
            // set POST request to /playlists
            [SCRequest performMethod:SCRequestMethodPOST
                          onResource:[NSURL URLWithString:@"https://api.soundcloud.com/playlists.json"]
                     usingParameters:parameters
                         withAccount:account
              sendingProgressHandler:^(unsigned long long bytesSent, unsigned long long bytesTotal){
                  CGFloat progress = (double)bytesSent / bytesTotal;
                  NSString *status = @"Creating set";
                  [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
              }
                     responseHandler:responseHandler];
        };
    }
    static void (^customNameAlertHandler)(UIAlertView *, NSInteger) = nil;
    if (customNameAlertHandler == nil) {
        customNameAlertHandler = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
                self.alertDelegate = setCreationAlertHandler;
                // pop a new alert to ask custom name
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Custom name for the Set:"
                                                                    message:nil
                                                                   delegate:self.alertDelegate
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alertView show];
            } else { // User tapped "No"
                // call set creation handler directly
                setCreationAlertHandler(alertView, buttonIndex);
            }
        };
    }
    self.alertDelegate = [[SRAlertViewDelegate alloc] initWithHandler:customNameAlertHandler];
    NSString *alertMsg = [NSString stringWithFormat:@"We are going to add the recordings to a new SoundCloud Set. "
                          "Its default name is \"%@\". Do you want to give a custom name instead?", defaultSetTitle];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Set creation"
                                                        message:alertMsg
                                                       delegate:self.alertDelegate
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"No", @""), NSLocalizedString(@"Yes", @""), nil];
    [alertView show];
}


- (void)uploadRecordingsWithEnumerator:(NSEnumerator *)enumerator
                             fileCount:(NSUInteger)n fileTotal:(NSUInteger)N
                      appendTracksIDTo:(NSMutableArray *)tracksID
                            doWhenDone:(void (^)(NSArray *))successHandler
                            doOnCancel:(void (^)())cancelHandler {
    // get the next recording to upload
    RecordingHandler *rec = [enumerator nextObject];
    if (rec) {
        // show progress
        CGFloat progress = (double)(n - 1) / N;
        NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", n, N];
        [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
        // upload the recording and recurse when done
        [self uploadRecording:rec fileCount:n fileTotal:N
                       doNext:^(NSString *trackID) {
                           if (trackID) {
                               // add uploaded track ID to the array
                               [tracksID addObject:trackID];
                           }
                           [self uploadRecordingsWithEnumerator:enumerator
                                                      fileCount:(n + 1) fileTotal:N
                                               appendTracksIDTo:tracksID
                                                     doWhenDone:successHandler
                                                     doOnCancel:cancelHandler];
                       }
                   doOnCancel:cancelHandler];
        
    } else { // no more recording to upload
        [SVProgressHUD showSuccessWithStatus:@"Uploaded"];
        successHandler(tracksID);
    }
}

- (void)uploadRecording:(RecordingHandler *)rec
              fileCount:(NSUInteger)n fileTotal:(NSUInteger)N
                 doNext:(void (^)(NSString *trackID))completionHandler
             doOnCancel:(void (^)())cancelHandler {
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
                            cancelHandler();
                        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Skip this one"]) {
                            // do next
                            completionHandler(nil);
                        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Try again"]) {
                            // try to upload recording again
                            [self uploadRecording:rec fileCount:n fileTotal:N doNext:completionHandler doOnCancel:cancelHandler];
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
                    completionHandler(nil);
                } else {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] < 300) {
                        // Ok, the upload succeed.
                        // Parse the response to get the created track ID.
                        NSDictionary *trackInfo = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        NSString *trackID = [NSString stringWithFormat:@"%@", [trackInfo valueForKey:@"id"]];
                        // do next
                        completionHandler(trackID);
                    }
                }
            }
        };
    }
    
    // send POST request to /tracks
    [SCRequest performMethod:SCRequestMethodPOST
                  onResource:[NSURL URLWithString:@"https://api.soundcloud.com/tracks.json"]
             usingParameters:parameters
                 withAccount:account
      sendingProgressHandler:^(unsigned long long bytesSent, unsigned long long bytesTotal){
          CGFloat progress = (double)bytesSent / (bytesTotal * N) + (double)(n - 1) / N;
          NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", n, N];
          [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
      }
             responseHandler:responseHandler];
    
}



- (void)removeOldRecordings {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *recDirURL = [[NSURL alloc] initFileURLWithPath: NSTemporaryDirectory()];
    NSArray *contents = [fileManager contentsOfDirectoryAtURL:recDirURL includingPropertiesForKeys:nil options:0 error:nil];
    for (NSURL *fileURL in contents) {
        if ([[fileURL pathExtension] isEqualToString:@"wav"]) {
            [fileManager removeItemAtURL:fileURL error:nil];
        }
    }
}

- (NSURL *)newFileURL {
    NSString *tempDir = NSTemporaryDirectory();
    // get a basename for the new file
    NSString *fileBasename = [NSString stringWithFormat: @"S%04d_%d.wav", self.sessionNo, self.fileCount];
    // get the URL
    NSString *filePath = [tempDir stringByAppendingString: fileBasename];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: filePath];
//    NSLog(@"sound file URL %@", [fileURL absoluteString]);
    // increment file counter
    self.fileCount++;
    return fileURL;
}

- (NSString *)popSentence {
    NSString *sentence = [self.sentencesRemaining objectAtIndex:0];
    [self.sentencesRemaining removeObjectAtIndex:0];
    return sentence;
}

- (void)cancel {
    [self performSegueWithIdentifier:@"CancelSession" sender:self];
}

- (void)done {
    [self performSegueWithIdentifier:@"DoneSession" sender:self];
}

@end
