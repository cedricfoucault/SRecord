//
//  SRAlertViewDelegate.m
//  SRecord
//
//  Created by Cédric Foucault on 6/3/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SRAlertViewDelegate.h"

@implementation SRAlertViewDelegate

- (id)initWithHandler:(void (^)(UIAlertView *, NSInteger))handler {
    self = [super init];
    if (self) {
        self.handler = handler;
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.handler) {
        self.handler(alertView, buttonIndex);
    }
}

@end
