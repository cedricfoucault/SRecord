//
//  EditSentencesViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 5/26/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SentenceCell.h"
@class SentencesController;

@interface EditSentencesViewController : UITableViewController <SentenceCellDelegate>

@property (strong, nonatomic) NSMutableArray *sentences;
@property (strong, nonatomic) SentencesController *dataSource;

- (IBAction)switchEditMode:(UIBarButtonItem *)sender;
- (IBAction)addAction:(UIBarButtonItem *)sender;

@end
