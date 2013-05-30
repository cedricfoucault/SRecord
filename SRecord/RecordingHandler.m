//
//  RecordingHandler.m
//  SRecord
//
//  Created by Cédric Foucault on 5/29/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "RecordingHandler.h"

@implementation RecordingHandler

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

@end