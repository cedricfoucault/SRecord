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

@property (copy, nonatomic) NSDate *sessionDate;
@property (nonatomic) NSUInteger currentNo;
@property (nonatomic) NSUInteger totalNo;
@property (copy, nonatomic) NSString *currentSentence;
@property (nonatomic, getter=isRecording) BOOL recording;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (strong, nonatomic) AVAudioRecorder *soundRecorder;
@property (strong, nonatomic) NSMutableArray *sentencesRemaining;
@property (strong, nonatomic) NSMutableArray *recordingsDone;
@property (strong, nonatomic) RecordingHandler *currentRecording;

- (void)customInit;
- (void)resetSessionVariables;
- (void)resetViews;
- (void)removeOldRecordings;
- (void)nextState;
- (void)endSession;
- (RecordingHandler *)prepareRecording;
- (void)startRecording;
- (void)stopRecording;
- (void)pauseRecording;
- (void)resumeRecording;
- (void)resetRecording;
- (void)commitRecording;
- (NSString *)popSentence;
- (NSURL *)currentFileURL;
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
    [self resetViews];
    [self nextState];
}

- (void)resetViews {
    // init views
    self.totalNoLabel.text = [NSString stringWithFormat:@"%d", self.totalNo];
    self.currentNoLabel.text = [NSString stringWithFormat:@"%d", self.currentNo];
    self.stopButton.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCurrentSentence:(NSString *)currentSentence {
    // tie to sentence label
    if (currentSentence != _currentSentence) {
        _currentSentence = [NSString stringWithString:currentSentence];
        self.sentenceLabel.text = _currentSentence;
    }
}

- (void)setCurrentNo:(NSUInteger)currentNo {
    if (_currentNo != currentNo) {
        _currentNo = currentNo;
        self.currentNoLabel.text = [NSString stringWithFormat:@"%d", _currentNo];
    }
}

- (void)setTotalNo:(NSUInteger)totalNo {
    if (_totalNo != totalNo) {
        _totalNo = totalNo;
        self.totalNoLabel.text = [NSString stringWithFormat:@"%d", _totalNo];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"UploadSegue"]) {
        UploadViewController *uploadController = [segue destinationViewController];
        uploadController.recordings = [NSArray arrayWithArray:self.recordingsDone];
        uploadController.sessionDate = self.sessionDate;
    }
}

- (void)startNewSessionWithSentences:(NSArray *)sentences {
    // set the sentences for this session
    [self.sentencesRemaining setArray:sentences];
    // init instance variables
    [self resetSessionVariables];
    // remove old recording files from temporary storage
    [self removeOldRecordings];
}

- (void)resetSessionVariables {
    // init instance variables for the new session
    [self.recordingsDone removeAllObjects];
    self.totalNo = [self.sentencesRemaining count];
    self.recording = NO;
    self.paused = NO;
    self.currentNo = 0;
    self.totalNo = [self.sentencesRemaining count];
    self.sessionDate = [NSDate date];
}

- (IBAction)handleTouchUpInside:(UIButton *)sender {
    if (sender == self.recButton) {
        if (self.isRecording) {
            if (self.isPaused) {
                // resume recording
                [self resumeRecording];
                // change button to pause
                UIColor *pauseTitleColor = [UIColor orangeColor];
                [self.recButton setTitle:@"Pause" forState:UIControlStateNormal];
                [self.recButton setTitle:@"Pause" forState:UIControlStateHighlighted];
                [self.recButton setTitleColor:pauseTitleColor forState:UIControlStateNormal];
                [self.recButton setTitleColor:pauseTitleColor forState:UIControlStateHighlighted];
                
            } else {
                // pause recording
                [self pauseRecording];
                // change button to resume
                UIColor *recordTitleColor = [UIColor redColor];
                [self.recButton setTitle:@"Resume" forState:UIControlStateNormal];
                [self.recButton setTitle:@"Resume" forState:UIControlStateHighlighted];
                [self.recButton setTitleColor:recordTitleColor forState:UIControlStateNormal];
                [self.recButton setTitleColor:recordTitleColor forState:UIControlStateHighlighted];
            }
//            [self stopRecording];
//            [self commitRecording];
//            [self nextState];
//            [sender setTitle:@"Record" forState:UIControlStateNormal];
//            [sender setTitle:@"Record" forState:UIControlStateHighlighted];
        } else {
            // start recording
            [self startRecording];
            // change button to pause
            UIColor *pauseTitleColor = [UIColor orangeColor];
            [self.recButton setTitle:@"Pause" forState:UIControlStateNormal];
            [self.recButton setTitle:@"Pause" forState:UIControlStateHighlighted];
            [self.recButton setTitleColor:pauseTitleColor forState:UIControlStateNormal];
            [self.recButton setTitleColor:pauseTitleColor forState:UIControlStateHighlighted];
//            [sender setTitle:@"Stop" forState:UIControlStateNormal];
//            [sender setTitle:@"Stop" forState:UIControlStateHighlighted];
        }
    } else if (sender == self.stopButton) {
        if (self.isRecording) {
            [self stopRecording];
            [self commitRecording];
            [self nextState];
            UIColor *recordTitleColor = [UIColor redColor];
            [self.recButton setTitle:@"Record" forState:UIControlStateNormal];
            [self.recButton setTitle:@"Record" forState:UIControlStateHighlighted];
            [self.recButton setTitleColor:recordTitleColor forState:UIControlStateNormal];
//            [sender setTitle:@"Record" forState:UIControlStateNormal];
//            [sender setTitle:@"Record" forState:UIControlStateHighlighted];
        }
        
    } else if (sender == self.resetButton) {
        if (self.isRecording) {
            [self resetRecording];
            UIColor *recordTitleColor = [UIColor redColor];
            [self.recButton setTitle:@"Record" forState:UIControlStateNormal];
            [self.recButton setTitle:@"Record" forState:UIControlStateHighlighted];
            [self.recButton setTitleColor:recordTitleColor forState:UIControlStateNormal];
        }
    }
}

- (IBAction)handleTouchDown:(UIButton *)sender {
    if (sender == self.stopButton) {
        if (self.isRecording) {
            // pause recording in order not to record the "tap" sound
            [self pauseRecording];
        }
    }
}

- (IBAction)handleTouchUpOutside:(UIButton *)sender {
    if (sender == self.stopButton) {
        if (self.isRecording) {
            // if we were recording, the recorder was paused when button was touched down
            // we have to resume it since the user decided not to click the button after all
            [self resumeRecording];
        }
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
        self.currentSentence = [self popSentence];
        self.currentNo++;
        self.currentRecording = [self prepareRecording];
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
    // enable stop button
    self.stopButton.enabled = YES;
}

- (void)stopRecording {
    // stop the recorder
    [self.soundRecorder stop];
    self.recording = NO;
    self.paused = NO;
    // release recorder
    self.soundRecorder = nil;
    // set session inactive
    [[AVAudioSession sharedInstance] setActive: NO error: nil];
    // disable stop button
    self.stopButton.enabled = NO;
}

- (void)pauseRecording {
    [self.soundRecorder pause];
    self.paused = YES;
}

- (void)resumeRecording {
    [self.soundRecorder record];
    self.paused = NO;
}

- (void)resetRecording {
    [self stopRecording];
    [self prepareRecording];
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

- (RecordingHandler *)prepareRecording {
    // init new recording handler
    NSURL *soundFileURL = [self currentFileURL];
    RecordingHandler *recordingHandler = [[RecordingHandler alloc] initWithFileURL:soundFileURL transcript:self.currentSentence sessionDate:self.sessionDate];
    // init audio session active
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
    // init recorder for upcoming recording
    static NSDictionary *recordSettings = nil;
    if (recordSettings == nil) {
        recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [NSNumber numberWithFloat: audioSession.sampleRate], AVSampleRateKey,
                          [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                          [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                          [NSNumber numberWithInt: AVAudioQualityMax],
                          AVEncoderAudioQualityKey,
                          nil];
    }
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

- (NSURL *)currentFileURL {
    NSString *tempDir = NSTemporaryDirectory();
    // get a basename for the new file
    static NSDateFormatter *fileDateFormatter = nil;
    if (fileDateFormatter == nil) {
        fileDateFormatter = [[NSDateFormatter alloc] init];
        [fileDateFormatter setLocale:[NSLocale currentLocale]];
        [fileDateFormatter setDateFormat:@"MMM-dd_HH:mm:ss"];
    }
    NSString * fileBasename = [NSString stringWithFormat:@"%@_%02d.wav", [fileDateFormatter stringFromDate:self.sessionDate], self.currentNo];
    // get the URL
    NSString *filePath = [tempDir stringByAppendingString: fileBasename];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: filePath];
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
