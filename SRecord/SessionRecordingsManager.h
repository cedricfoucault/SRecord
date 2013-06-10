//
//  RecordingsController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/9/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SessionHandler;

@interface SessionRecordingsManager : NSObject

+ (void)saveSessionWithDate:(NSDate *)date recordings:(NSArray *)recordings SCSetName:(NSString *)name;
+ (NSArray *)savedSessions;
+ (NSArray *)URLsOfSavedSessions;
+ (SessionHandler *)loadSessionWithURL:(NSURL *)sessionURL;
+ (void)deleteSession:(SessionHandler *)session;

@end
