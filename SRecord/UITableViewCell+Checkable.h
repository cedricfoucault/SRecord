//
//  UITableViewCell+Checkable.h
//  SRecord
//
//  Created by Cédric Foucault on 6/8/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewCell (Checkable)

- (BOOL)isChecked;
- (void)setChecked:(BOOL)checked;

@end
