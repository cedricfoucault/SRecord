//
//  SessionHandler.h
//  SRecord
//
//  Created by Cédric Foucault on 6/9/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SessionHandler : NSObject <NSCoding>

@property (copy, nonatomic) NSDate *date;
@property (copy, nonatomic) NSArray *recordings;
@property (copy, nonatomic) NSString *SCSetName;

- (id)initWithDate:(NSDate *)date recordings:(NSArray *)recordings SCSetName:(NSString *)SCSetName;

@end
