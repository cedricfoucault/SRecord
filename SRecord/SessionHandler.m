//
//  SessionHandler.m
//  SRecord
//
//  Created by Cédric Foucault on 6/9/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SessionHandler.h"

@implementation SessionHandler

- (id)initWithDate:(NSDate *)date recordings:(NSArray *)recordings SCSetName:(NSString *)SCSetName {
    self = [self init];
    if (self) {
        self.date = date;
        self.recordings = recordings;
        self.SCSetName = SCSetName;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self) {
        self.date = [aDecoder decodeObjectForKey:@"date"];
        self.recordings = [aDecoder decodeObjectForKey:@"recordings"];
        self.SCSetName = [aDecoder decodeObjectForKey:@"SCSetName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeObject:self.recordings forKey:@"recordings"];
    [aCoder encodeObject:self.SCSetName forKey:@"SCSetName"];
}

@end
