//
//  RecordingsController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/9/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SessionRecordingsManager.h"
#import "SessionHandler.h"
#import "RecordingHandler.h"
#import "ErrorHelper.h"

@interface SessionRecordingsManager ()

+ (NSURL *)directoryURLForDate:(NSDate *)date;
+ (NSString *)directoryNameForDate:(NSDate *)date;
+ (NSURL *)savedSessionsDirectoryURL;
+ (NSURL *)sessionURLAtDirectoryURL:(NSURL *)dirURL;
+ (NSURL *)recordingFileURLFromOriginalURL:(NSURL *)fromURL atDirectoryURL:(NSURL *)dirURL;
+ (void)saveSession:(SessionHandler *)session atURL:(NSURL *)url;

@end

@implementation SessionRecordingsManager

+ (void)saveSessionWithDate:(NSDate *)date recordings:(NSArray *)recordings SCSetName:(NSString *)name {
    // create the directory for the session
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *dirURL = [self directoryURLForDate:date];
    NSError* error = nil;
    BOOL wasCreated = [fileManager createDirectoryAtURL:dirURL withIntermediateDirectories:YES attributes:nil error:&error];
    if (!wasCreated) {
        NSLog(@"%@", [ErrorHelper genericMsgWithError:error]);
        return;
    }
    // move recording sound files to the created directory
    for (RecordingHandler *rec in recordings) {
        // get the new file URL from the original
        NSURL *newFileURL = [self recordingFileURLFromOriginalURL:rec.fileURL atDirectoryURL:dirURL];
        // move the file at the new URL
        BOOL wasMoved = [fileManager moveItemAtURL:rec.fileURL toURL:newFileURL error:&error];
        if (!wasMoved) {
            NSLog(@"%@", [ErrorHelper genericMsgWithError:error]);
            return;
        }
        // change the fileURL property
        rec.fileURL = newFileURL;
    }
    // save session handler in the directory as keyed archive
    SessionHandler *session = [[SessionHandler alloc] initWithDate:date recordings:recordings SCSetName:name];
    NSURL *sessionURL = [self sessionURLAtDirectoryURL:dirURL];
    [self saveSession:session atURL:sessionURL];
}

+ (NSArray *)savedSessions {
    NSArray *urls = [self URLsOfSavedSessions];
    NSMutableArray *sessions = [[NSMutableArray alloc] initWithCapacity:[urls count]];
    for (NSURL *url in urls) {
        [sessions addObject:[self loadSessionWithURL:url]];
    }
    return sessions;
}

+ (NSArray *)URLsOfSavedSessions {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // enumerate contents in the directory for the saved sessions
    NSURL *dirURL = [self savedSessionsDirectoryURL];
    NSArray *keys = [NSArray arrayWithObjects:NSURLIsDirectoryKey, nil];
    NSError* error = nil;
    NSArray *urls = [fileManager contentsOfDirectoryAtURL:dirURL
                               includingPropertiesForKeys:keys
                                                  options:0
                                                    error:&error];
    if (error) {
        NSLog(@"%@", [ErrorHelper genericMsgWithError:error]);
    }
    NSMutableArray *sessionsURLs = [[NSMutableArray alloc] init];
    for (NSURL *url in urls) {
        // keep only url of directories
        NSNumber *isDirectory = nil;
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        if ([isDirectory boolValue]) {
            // get the session handler url
            [sessionsURLs addObject:[self sessionURLAtDirectoryURL:url]];
        }
    }
    return sessionsURLs;
}

+ (SessionHandler *)loadSessionWithURL:(NSURL *)sessionURL {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[sessionURL path]];
}

+ (void)saveSession:(SessionHandler *)session atURL:(NSURL *)url {
    [NSKeyedArchiver archiveRootObject:session toFile:[url path]];
}

+ (void)deleteSession:(SessionHandler *)session {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *sessionDir = [self directoryURLForDate:session.date];
    NSError *error = nil;
    [fileManager removeItemAtURL:sessionDir error:&error];
    if (error) {
        NSLog(@"%@", [ErrorHelper genericMsgWithError:error]);
    }
}

+ (NSURL *)directoryURLForDate:(NSDate *)date {
    // retrieve the URL of the directory for the saved sessions
    NSURL *savedSessionsDirectoryURL = [self savedSessionsDirectoryURL];
    // build subdirectory name from date
    NSString *sessionDirectoryName = [self directoryNameForDate:date];
    // return URL "savedSessionsDirectoryURL/sessionDirectoryName/"
    return [savedSessionsDirectoryURL URLByAppendingPathComponent:sessionDirectoryName isDirectory:YES];
}

+ (NSString *)directoryNameForDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"MMM-dd_HH:mm:ss"];
    }
    return [dateFormatter stringFromDate:date];
}

+ (NSURL *)savedSessionsDirectoryURL {
    static NSString *savedSessionsDirectoryName = @"Saved Sessions";
    // retrieve document directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectoryURL = [URLs objectAtIndex:0];
    // return "documentsDirectoryURL/savedSessionsDirectoryName"
    return [documentsDirectoryURL URLByAppendingPathComponent:savedSessionsDirectoryName];
}

+ (NSURL *)sessionURLAtDirectoryURL:(NSURL *)dirURL {
    return [dirURL URLByAppendingPathComponent:@"sessionHandler"];
}

+ (NSURL *)recordingFileURLFromOriginalURL:(NSURL *)fromURL atDirectoryURL:(NSURL *)dirURL {
    NSString *fileName = [fromURL lastPathComponent];
    return [dirURL URLByAppendingPathComponent:fileName];
}

@end
