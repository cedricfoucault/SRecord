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
    if (checked) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
        self.textLabel.textColor = [UIColor blackColor];
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.textLabel.textColor = [UIColor darkGrayColor];
    }
}


@end
