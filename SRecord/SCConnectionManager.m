//
//  SCConnectionManager.m
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SCConnectionManager.h"
#import <SCUI.h>
#import <SCUIErrors.h>
#import <NXOAuth2Constants.h>
#import "ErrorHelper.h"

static SCLoginViewController *loginViewController;

@interface SCConnectionManager ()

+ (void) presentLoginViewControllerWithPresenter:(UIViewController *)presenter completion:(void (^)(NSError *))handler;

@end

@implementation SCConnectionManager

+ (void)presentLoginViewControllerWithPresenter:(UIViewController *)presenter doOnSuccess:(void (^)())successHandler doOnCancel:(void (^)())cancelHandler {
    void (^login_handler)(NSError *) = ^(NSError *error) {
        if (error) {
            NSString *alertTitle;
            NSString *alertMsg;
            if (SC_CANCELED(error)) {
                // login was canceled, perform handler and return
                cancelHandler();
                return;
                // else display an alert with appropriate error message
            } else if ([[error domain] isEqualToString:NSURLErrorDomain]) {
                switch ([error code]) {
                    case NSURLErrorNotConnectedToInternet:
                        alertTitle = @"No Internet Connection";
                        alertMsg = @"Cannot connect to the internet. Service may not be available.";
                        break;
                        
                    case NSURLErrorCannotConnectToHost:
                        alertTitle = @"Host Unavailable";
                        alertMsg = @"Cannot connect to SoundCloud. Server may be down.";
                        break;
                        
                    default:
                        alertTitle = @"Request failed";
                        alertMsg = [ErrorHelper genericMsgWithError:error];
                        break;
                }
            } else if ([[error domain] isEqualToString:NXOAuth2HTTPErrorDomain]) {
                switch ([error code]) {
                    case 401:
                        alertTitle = @"Check credentials";
                        alertMsg = @"The credentials provided seem to be invalid.";
                        break;
                        
                    default:
                        alertTitle = @"HTTP error";
                        alertMsg = [ErrorHelper genericMsgWithError:error];
                        break;
                }
            } else {
                alertTitle = @"Log in failed";
                alertMsg = [ErrorHelper genericMsgWithError:error];
            }
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                            message:alertMsg
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                                  otherButtonTitles:nil];
            [alert show];
        } else { // no error
            successHandler();
        }
    };
    
    [self presentLoginViewControllerWithPresenter:presenter completion:login_handler];
}

+ (void) presentLoginViewControllerWithPresenter:(UIViewController *)presenter completion:(void (^)(NSError *))handler {
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
        loginViewController = [SCLoginViewController loginViewControllerWithPreparedURL:preparedURL
                                                                      completionHandler:^(NSError *error){
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
