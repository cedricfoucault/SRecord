//
//  RecordingHandler.m
//  SRecord
//
//  Created by Cédric Foucault on 5/29/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "RecordingHandler.h"

static NSDateFormatter *titleDateFormatter = nil;

@implementation RecordingHandler

@synthesize trackTitle = _trackTitle;

- (id)initWithFileURL:(NSURL *)URL {
    self = [self init];
    self.fileURL = URL;
    return self;
}

- (id)initWithFileURL:(NSURL *)URL transcript:(NSString *)transcript {
    self = [self initWithFileURL:URL];
    self.transcript = transcript;
    return self;
}

- (id)initWithFileURL:(NSURL *)URL transcript:(NSString *)transcript sessionDate:(NSDate *)date {
    self = [self initWithFileURL:URL transcript:transcript];
    self.sessionDate = date;
    return self;
}

- (NSString *)trackTitle {
    // lazy init
    if (!_trackTitle) {
        if (titleDateFormatter == nil) {
            titleDateFormatter = [[NSDateFormatter alloc] init];
            titleDateFormatter.locale = [NSLocale currentLocale];
            titleDateFormatter.dateFormat = @"MMM d, h:m a";
        }
        NSString *dateString = [titleDateFormatter stringFromDate:self.sessionDate];
        _trackTitle = [NSString stringWithFormat:@"%@ - %@", dateString, self.transcript];
    }
    
    return _trackTitle;
}

@end
