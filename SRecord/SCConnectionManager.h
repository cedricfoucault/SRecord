//
//  SCConnectionManager.h
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCConnectionManager : NSObject

+ (BOOL) isLoggedIn;
+ (void) presentLoginViewControllerWithPresenter:(UIViewController *)presenter completion:(void (^)(NSError *))handler;
+ (void) presentLoginViewControllerWithPresenter:(UIViewController *)presenter
                                      doOnSuccess:(void (^)())successHandler
                                      doOnCancel:(void (^)())cancelHandler;
+ (NSString *) alertGenericMsgWithError:(NSError *)error;
+ (void) logOut;

@end
