//
//  SCConnectionManager.m
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SCConnectionManager.h"
//#import <SCSoundCloud.h>
#import <SCUI.h>

static SCLoginViewController *loginViewController;

@interface SCConnectionManager ()

//@property (strong, nonatomic) SCLoginViewController *loginViewController;

@end

@implementation SCConnectionManager

+ (void) presentLoginViewControllerWithPresenter:(UIViewController *)presenter completion:(void (^)(NSError *))handler {
    //    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:kSCAccountType
    //                                                              username:kSRSoundCloudUsername
    //                                                              password:kSRSoundCloudPassword];
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
        loginViewController = [SCLoginViewController loginViewControllerWithPreparedURL:preparedURL
                                                                      completionHandler:^(NSError *error){
                                                                          
//                                                                          if (SC_CANCELED(error)) {
//                                                                              NSLog(@"Canceled!");
//                                                                          } else if (error) {
//                                                                              NSLog(@"Ooops, something went wrong: %@", [error localizedDescription]);
//                                                                          } else {
//                                                                              NSLog(@"Done!");
//                                                                          }
                                                                          handler(error);
                                                                      }];
        
        [presenter presentViewController:loginViewController animated:YES completion:nil];
    }];
}

+ (BOOL) isLoggedIn {
    return ([SCSoundCloud account] != nil);
}

+ (void)logOut {
    [SCSoundCloud removeAccess];
}

@end
