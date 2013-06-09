//
//  UploadController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/8/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RecordingHandler;

@protocol UploadControllerDelegate <NSObject>

- (void)didFinishUploading;
- (void)didCancelUploading;

@end

@interface UploadController : NSObject

@property (weak, nonatomic) UIViewController <UploadControllerDelegate> *delegate;

- (id)initWithDelegate:(UIViewController <UploadControllerDelegate> *)delegate;

- (void)uploadTracksWithRecordings:(NSArray *)recordings SCSetName:(NSString *)name;

- (void)uploadTrackWithRecording:(RecordingHandler *)rec
       progressHandler:(void (^)(unsigned long long bytesSend, unsigned long long bytesTotal))progressHandler
       responseHandler:(void (^)(NSURLResponse *response, NSData *responseData, NSError *error))responseHandler;;

- (void)createSCSetWithName:(NSString *)name tracks:(NSArray *)tracksID
            progressHandler:(void (^)(unsigned long long bytesSend, unsigned long long bytesTotal))progressHandler
            responseHandler:(void (^)(NSURLResponse *response, NSData *responseData, NSError *error))responseHandler;

- (NSDictionary *)parseResponseData:(NSData *)data;

@end
