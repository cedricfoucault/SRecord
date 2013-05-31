//
//  SessionEndViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 5/29/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RecordingHandler;

@interface SessionEndViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *recordings; // recordings to be uploaded

- (void)startUploading;
- (void)loginToSC;

@end
