//
//  ErrorHelper.m
//  SRecord
//
//  Created by Cédric Foucault on 6/5/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "ErrorHelper.h"

@implementation ErrorHelper

+ (NSString *)genericMsgWithError:(NSError *)error {
    NSMutableString *msg = [NSMutableString stringWithFormat:@"%@.", [error localizedDescription]];
    if ([error localizedFailureReason]) {
        [msg appendString:[NSString stringWithFormat:@" %@.", [error localizedFailureReason]]];
    }
    if ([error localizedRecoverySuggestion]) {
        [msg appendString:[NSString stringWithFormat:@" %@.", [error localizedRecoverySuggestion]]];
    }
    return [NSString stringWithString:msg];
}

@end
