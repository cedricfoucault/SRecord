//
//  RecordingHandler.h
//  SRecord
//
//  Created by Cédric Foucault on 5/29/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordingHandler : NSObject <NSCoding>

@property (copy, nonatomic) NSURL *fileURL;
@property (copy, nonatomic) NSString *transcript;
@property (copy, nonatomic) NSDate *sessionDate;
@property (readonly, nonatomic) NSString *trackTitle;

- (id) initWithFileURL:(NSURL *)URL;
- (id) initWithFileURL:(NSURL *)URL transcript:(NSString *)transcript;
- (id) initWithFileURL:(NSURL *)URL transcript:(NSString *)transcript sessionDate:(NSDate *) date;


@end
