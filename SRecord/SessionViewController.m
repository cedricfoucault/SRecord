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
#import "UploadViewController.h"

@interface SessionViewController ()

@property (nonatomic) NSInteger sessionNo;
@property (nonatomic, getter=isRecording) BOOL recording;
@property (strong, nonatomic) AVAudioRecorder *soundRecorder;
@property (strong, nonatomic) NSMutableArray *sentencesRemaining;
@property (strong, nonatomic) NSMutableArray *recordingsDone;
@property (strong, nonatomic) RecordingHandler *currentRecording;
@property (nonatomic) int fileCount;

- (void)customInit;
- (void)removeOldRecordings;
- (RecordingHandler *)prepareNewRecording;
- (void)startRecording;
- (void)stopRecording;
- (void)nextState;
- (void)endSession;
- (NSString *)popSentence;
- (NSURL *)newFileURL;
- (void)commitRecording;
- (void)cancel;
- (void)done;

@end

@implementation SessionViewController

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
    self.recordingsDone = [[NSMutableArray alloc] init];
    self.sentencesRemaining = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
    // reset file count and recordings done
    self.fileCount = 0;
    [self.recordingsDone removeAllObjects];
    self.recording = NO;
    [self.sentencesRemaining setArray:sentences];
    self.sessionNo = arc4random_uniform(9999); // generate a random session number of <= 4 digits
    // remove old recording files from temporary storage
    [self removeOldRecordings];
}

- (IBAction)handleTouchUpInside:(UIButton *)recButton {
    if (self.isRecording) {
        [self stopRecording];
        [self commitRecording];
        [self nextState];
        [recButton setTitle:@"Record" forState:UIControlStateNormal];
        [recButton setTitle:@"Record" forState:UIControlStateHighlighted];
    } else {
        [self startRecording];
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
    [SVProgressHUD showSuccessWithStatus:@"All done"];
    [self performSegueWithIdentifier:@"UploadSegue" sender:self];
    
}

- (void)endSessionPrematurely {
    if ([self.soundRecorder isRecording]) {
        [self stopRecording];
    }
    [self performSegueWithIdentifier:@"UploadSegue" sender:self];
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
