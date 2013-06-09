//
//  UploadViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/5/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UploadViewController : UIViewController <UIAlertViewDelegate>

@property (copy, nonatomic) NSDate *sessionDate;
@property (strong, nonatomic) NSArray *recordings;
- (IBAction)okButtonTapped:(id)sender;

@end
