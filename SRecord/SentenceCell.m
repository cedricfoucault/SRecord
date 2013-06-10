//
//  SentenceCell.m
//  SRecord
//
//  Created by Cédric Foucault on 5/26/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SentenceCell.h"

@implementation SentenceCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.sentenceInput) {
        [self.delegate sentenceCellContentDidChange:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.sentenceInput) {
//        [self.delegate sentenceCellContentDidChange:self];
        [textField resignFirstResponder];
    }
    return YES;
}

@end
