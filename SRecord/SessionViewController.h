//
//  SessionViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 5/27/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioRecorder.h>
@class RecordingHandler;

@interface SessionViewController : UIViewController <AVAudioRecorderDelegate, UIAlertViewDelegate>

@property (nonatomic) NSInteger sessionNo;
@property (nonatomic, getter=isRecording) BOOL recording;
@property (strong, nonatomic) NSMutableArray *sentencesRemaining;
@property (strong, nonatomic) NSMutableArray *recordingsDone;
@property (weak, nonatomic) IBOutlet UILabel *sentenceLabel;
@property (strong, nonatomic) AVAudioRecorder *soundRecorder;
@property (strong, nonatomic) RecordingHandler *currentRecording;


- (void)startNewSessionWithSentences:(NSArray *)sentences;
- (void)removeOldRecordings;
- (IBAction)record:(UIButton *)recButton;
- (RecordingHandler *)prepareNewRecording;
- (void)startRecording;
- (void)stopRecording;
- (void)nextState;
- (void)endSession;
- (void)loginToSC;
- (void)startUploadingWithCompletionHandler:(void (^)(NSError *))handler;


@end
