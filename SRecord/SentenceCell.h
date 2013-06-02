//
//  SentenceCell.h
//  SRecord
//
//  Created by Cédric Foucault on 5/26/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SentenceCellDelegate;

@interface SentenceCell : UITableViewCell <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *sentenceInput;
@property (unsafe_unretained, nonatomic) id<SentenceCellDelegate> delegate;

@end

@protocol SentenceCellDelegate

- (void) sentenceCellContentDidChange:(SentenceCell *)sender;

@end
