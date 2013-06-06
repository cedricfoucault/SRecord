//
//  SRAlertViewDelegate.h
//  SRecord
//
//  Created by Cédric Foucault on 6/3/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRAlertViewDelegate : NSObject <UIAlertViewDelegate>

@property (strong, nonatomic) void (^handler)(UIAlertView *, NSInteger);

- (id)initWithHandler:(void (^)(UIAlertView *, NSInteger))handler;

@end
