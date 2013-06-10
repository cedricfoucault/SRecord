//
//  UploadViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/8/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol UploadControllerDelegate;

@interface UploadViewController : UIViewController

@property (copy, nonatomic) NSDate *sessionDate;
@property (strong, nonatomic) NSArray *recordings;
@property (copy, nonatomic) NSString *defaultSCSetName;

@end
