//
//  SentencesController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SentencesManager.h"

@interface SentencesManager ()

+ (NSString *)sentencesFilePath;

@end

@implementation SentencesManager

+ (NSString *)sentencesFilePath {
    static NSString *path = nil;
    if (path == nil) {
        // retrieve document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        // get filepath in this directory
        path = [documentsPath stringByAppendingPathComponent:@"sentences"];
    }
    return path;
}

+ (NSArray *)loadSentences {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self sentencesFilePath]];
}

+ (void)saveSentences:(NSArray *)sentences {
    [NSKeyedArchiver archiveRootObject:sentences toFile:[self sentencesFilePath]];
}

@end
