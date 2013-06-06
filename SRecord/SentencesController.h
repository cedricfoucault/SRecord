//
//  SentencesController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SentencesController : NSObject

+ (NSArray *)loadSentences;
+ (void)saveSentences:(NSArray *)sentences;

@end
