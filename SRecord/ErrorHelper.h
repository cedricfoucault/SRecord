//
//  ErrorHelper.h
//  SRecord
//
//  Created by Cédric Foucault on 6/5/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ErrorHelper : NSObject

+ (NSString *) genericMsgWithError:(NSError *)error;

@end
