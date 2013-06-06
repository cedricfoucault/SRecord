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

@property (weak, nonatomic) IBOutlet UILabel *sentenceLabel;
@property (weak, nonatomic) IBOutlet UIButton *quitButton;


- (void)startNewSessionWithSentences:(NSArray *)sentences;
- (IBAction)handleTouchUpInside:(UIButton *)recButton;
- (IBAction)handleTouchDown:(UIButton *)recButton;
- (IBAction)handleTouchUpOutside:(UIButton *)recButton;
- (IBAction)quitTapped:(UIButton *)sender;


@end
