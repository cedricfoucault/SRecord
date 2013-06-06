//
//  SetCreationViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/5/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetCreationViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSArray *tracksID;
@property (copy, nonatomic) NSString *defaultSetTitle;
@property (weak, nonatomic) IBOutlet UILabel *nameInfoLabel;
@property (weak, nonatomic) IBOutlet UITextField *customNameInput;
@property (strong, nonatomic) NSString *customName;


- (IBAction)okButtonTapped:(id)sender;

@end
