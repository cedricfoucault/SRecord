//
//  UploadController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/8/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RecordingHandler;
@class SessionHandler;

@protocol UploadControllerDelegate <NSObject>

- (void)didFinishUploading;
- (void)didCancelUploading;

@end

@interface UploadController : NSObject

@property (weak, nonatomic) UIViewController <UploadControllerDelegate> *delegate;

- (id)initWithDelegate:(UIViewController <UploadControllerDelegate> *)delegate;

- (void)uploadTracksWithRecordings:(NSArray *)recordings SCSetName:(NSString *)name;
- (void)uploadSession:(SessionHandler *)session;


@end
