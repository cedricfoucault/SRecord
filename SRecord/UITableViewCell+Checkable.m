//
//  UITableViewCell+Checkable.m
//  SRecord
//
//  Created by Cédric Foucault on 6/8/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "UITableViewCell+Checkable.h"

@implementation UITableViewCell (Checkable)

- (BOOL)isChecked {
    return self.accessoryType == UITableViewCellAccessoryCheckmark;
}

- (void)setChecked:(BOOL)checked {
    static UIColor *uncheckedTextColor = nil;
    static UIColor *checkedTextColor = nil;
    if (uncheckedTextColor == nil) {
        uncheckedTextColor = [UIColor darkGrayColor];
//        uncheckedTextColor = [UIColor blackColor];
    }
    if (checkedTextColor == nil) {
        checkedTextColor = [UIColor blackColor];
//        checkedTextColor = [UIColor colorWithRed:0.243 green:0.306 blue:0.435 alpha:1.0];
    }
    if (checked) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
        self.textLabel.textColor = checkedTextColor;
//        self.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.textLabel.textColor = uncheckedTextColor;
//        self.textLabel.font = [UIFont systemFontOfSize:17.0];
    }
}


@end
