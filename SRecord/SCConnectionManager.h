//
//  SCConnectionManager.h
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCConnectionManager : NSObject

@property (readonly, getter = isLoggedIn, nonatomic) BOOL loggedIn;

- (void)presentLoginViewControllerWithPresenter:(UIViewController *)presenter completion:(void (^)())handler;
- (void)logOut;

@end
