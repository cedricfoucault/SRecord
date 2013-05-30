//
//  EditSentencesViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 5/26/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SentenceCell.h"

@interface EditSentencesViewController : UITableViewController <SentenceCellDelegate>

@property (strong, nonatomic) NSMutableArray *sentences;

- (IBAction)switchEditMode:(UIBarButtonItem *)sender;

@end
