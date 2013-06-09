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

@interface SessionViewController : UIViewController <AVAudioRecorderDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *currentNoLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalNoLabel;
@property (weak, nonatomic) IBOutlet UILabel *sentenceLabel;
@property (weak, nonatomic) IBOutlet UIButton *quitButton;
@property (weak, nonatomic) IBOutlet UIButton *recButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

- (void)startNewSessionWithSentences:(NSArray *)sentences;
- (IBAction)handleTouchUpInside:(UIButton *)sender;
- (IBAction)handleTouchDown:(UIButton *)sender;
- (IBAction)handleTouchUpOutside:(UIButton *)recButton;
- (IBAction)quitTapped:(UIButton *)sender;


@end
