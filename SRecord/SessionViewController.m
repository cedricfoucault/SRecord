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


@interface SessionViewController ()

@property (nonatomic) int fileCount;
//@property (strong, nonatomic) UIImage *startRecordIcon;
//@property (strong, nonatomic) UIImage *startRecordPressedIcon;
//@property (strong, nonatomic) UIImage *stopRecordIcon;

- (NSString *)popSentence;
- (NSURL *)newFileURL;
- (void)commitRecording;

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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Done!" message:@"The samples for this session have all been recorded. We will now upload the recordings to SoundCloud." delegate:self cancelButtonTitle:@"Don't Upload" otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView cancelButtonIndex]) {
        [self performSegueWithIdentifier:@"CancelSession" sender:self];
    } else {
        // login to soundcloud if necessary
        if (![SCConnectionManager isLoggedIn]) {
            [SCConnectionManager presentLoginViewControllerWithPresenter:self completion:^(NSError *error) {
                // upload the recordings
                [self startUploadingWithCompletionHandler:^(NSError *error) {
                    // go back to main menu
                    [SVProgressHUD showSuccessWithStatus:@"Uploaded"];
                    [self performSegueWithIdentifier:@"DoneSession" sender:self];
                }];
            }];
        } else {
            // upload the recordings
            [self startUploadingWithCompletionHandler:^(NSError *error) {
                // go back to main menu
                [SVProgressHUD showSuccessWithStatus:@"Uploaded"];
                [self performSegueWithIdentifier:@"DoneSession" sender:self];
            }];
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

- (void)startUploadingWithCompletionHandler:(void (^)(NSError *))handler {
    NSLog(@"Start uploading");
    // upload recording by recording
    NSUInteger n = 1;
    NSUInteger N = [self.recordingsDone count];
    NSEnumerator *enumerator = [self.recordingsDone objectEnumerator];
    [SVProgressHUD showProgress:0.0 status:[NSString stringWithFormat:@"Uploading %d of %d", n, N] maskType:SVProgressHUDMaskTypeBlack];
    [self uploadRecordingsWithEnumerator:enumerator fileCount:n fileTotal:N completionHandler:handler];
}

- (void)uploadRecordingsWithEnumerator:(NSEnumerator *)enumerator fileCount:(NSUInteger)n fileTotal:(NSUInteger)N completionHandler:(void (^)(NSError *))handler {
    // get the next recording to upload
    RecordingHandler *rec = [enumerator nextObject];
    if (rec) {
        // set parameters for the track to upload
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
        // send POST request to /tracks
        [SCRequest performMethod:SCRequestMethodPOST
                      onResource:[NSURL URLWithString:@"https://api.soundcloud.com/tracks.json"]
                 usingParameters:parameters
                     withAccount:account
          sendingProgressHandler:^(unsigned long long bytesSent, unsigned long long bytesTotal){
              CGFloat progress = (double)(bytesSent * n) / (bytesTotal * N);
              NSString *status = [NSString stringWithFormat:@"Uploading %d of %d", n, N];
              [SVProgressHUD showProgress:progress status:status maskType:SVProgressHUDMaskTypeBlack];
          }
                 responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                     if (error) {
                         NSLog(@"Ooops, something went wrong! %@", [error localizedDescription]);
                     } else {
                         if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                             NSLog(@"Expecting a NSURLHTTPResponse.");
                         } else {
                             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                             if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] < 300) {
                                 // Ok, the upload succeed
                                 // Parse the response if you want to have the info of the uploaded track.
                                 NSLog(@"Uploaded %@.", [[rec.fileURL absoluteString] lastPathComponent]);
                             }
                         }
                     }
                     // upload next recording
                     [self uploadRecordingsWithEnumerator:enumerator fileCount:(n + 1) fileTotal:N completionHandler:handler];
                 }];
    } else { // no more recording to upload
        // when done, call the completion handler
        handler(nil);
    }
    
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

@end
