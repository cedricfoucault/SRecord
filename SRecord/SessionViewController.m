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
#import "SessionEndViewController.h"

@interface SessionViewController ()

@property (nonatomic) int fileCount;

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

- (IBAction)record:(UIButton *)recButton {
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
        [self performSegueWithIdentifier:@"ShowSessionEnd" sender:self];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowSessionEnd"]) {
        SessionEndViewController *endController = [segue destinationViewController];
        endController.recordings = self.recordingsDone;
        self.recordingsDone = nil;
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
