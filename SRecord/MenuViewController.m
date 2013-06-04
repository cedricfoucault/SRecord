//
//  MenuViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "MenuViewController.h"
#import "SidePanelController.h"
#import "SCConnectionManager.h"
#import <SVProgressHUD.h>
#import <SCUIErrors.h>
#import <NXOAuth2Constants.h>

@interface MenuViewController ()

- (void) updateConnectionStatusLabel;
- (NSString *) alertGenericMsgWithError:(NSError *)error;

@end

@implementation MenuViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateConnectionStatusLabel];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    static const NSUInteger HOME_ROWINDEX = 0;
    static const NSUInteger SENTENCES_ROWINDEX = 1;
    static const NSUInteger CONNECTIONSTATUS_ROWINDEX = 2;
    switch (indexPath.row) {
        case HOME_ROWINDEX:
            self.sidePanelController.centerPanel = self.sidePanelController.homeViewController;
            break;
        case SENTENCES_ROWINDEX:
            self.sidePanelController.centerPanel = self.sidePanelController.sentencesViewController;
            break;
        case CONNECTIONSTATUS_ROWINDEX:
            if ([SCConnectionManager isLoggedIn]) {
                [SCConnectionManager logOut];
                [self updateConnectionStatusLabel];
                [SVProgressHUD showSuccessWithStatus:@"Logged out"];
            } else {
                void (^successHandler)() = ^() {
                    [self updateConnectionStatusLabel];
                    if ([SCConnectionManager isLoggedIn]) {
                        [SVProgressHUD showSuccessWithStatus:@"Logged in"];
                    }
                };
                void (^cancelHandler)() = ^() {};
                [SCConnectionManager presentLoginViewControllerWithPresenter:self
                                                                 doOnSuccess:successHandler
                                                                  doOnCancel:cancelHandler];
//                void (^login_handler)(NSError *) = ^(NSError *error) {
//                    if (error) {
//                        NSString *alertTitle;
//                        NSString *alertMsg;
//                        if (SC_CANCELED(error)) {
//                            // login was canceled, do nothing
//                            return;
//                        } else if ([[error domain] isEqualToString:NSURLErrorDomain]) {
//                            switch ([error code]) {
//                                case NSURLErrorNotConnectedToInternet:
//                                    alertTitle = @"No Internet Connection";
//                                    alertMsg = @"Cannot connect to the internet. Service may not be available.";
//                                    break;
//                                    
//                                case NSURLErrorCannotConnectToHost:
//                                    alertTitle = @"Host Unavailable";
//                                    alertMsg = @"Cannot connect to SoundCloud. Server may be down.";
//                                    break;
//                                    
//                                default:
//                                    alertTitle = @"Request failed";
//                                    alertMsg = [self alertGenericMsgWithError:error];
//                                    break;
//                            }
//                        } else if ([[error domain] isEqualToString:NXOAuth2HTTPErrorDomain]) {
//                            switch ([error code]) {
//                                case 401:
//                                    alertTitle = @"Oops";
//                                    alertMsg = @"The credentials provided seem to be invalid. Please check them and type them again.";
//                                    break;
//                                    
//                                default:
//                                    alertTitle = @"HTTP error";
//                                    alertMsg = [self alertGenericMsgWithError:error];
//                                    break;
//                            }
//                        } else {
//                            alertTitle = @"Log in failed";
//                            alertMsg = [self alertGenericMsgWithError:error];
//                        }
//                        
//                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
//                                                                        message:alertMsg
//                                                                       delegate:nil
//                                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
//                                                              otherButtonTitles:nil];
//                        [alert show];
//                    } else { // no error
//                        [self updateConnectionStatusLabel];
//                        if ([SCConnectionManager isLoggedIn]) {
//                            [SVProgressHUD showSuccessWithStatus:@"Logged in"];
//                        }
//                    }
//                };
//                [SCConnectionManager presentLoginViewControllerWithPresenter:self.sidePanelController
//                                                                  completion:login_handler];
            }
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
    }
}

- (void) updateConnectionStatusLabel {
    if ([SCConnectionManager isLoggedIn]) {
        self.connectionStatusLabel.text = @"Log Out";
    } else {
        self.connectionStatusLabel.text = @"Log In";
    }
}

- (NSString *)alertGenericMsgWithError:(NSError *)error {
    NSMutableString *msg = [NSMutableString stringWithFormat:@"%@.", [error localizedDescription]];
    if ([error localizedFailureReason]) {
        [msg appendString:[NSString stringWithFormat:@" %@.",
                           [error localizedFailureReason]]];
    }
    if ([error localizedRecoverySuggestion]) {
        [msg appendString:[NSString stringWithFormat:@" %@.",
                           [error localizedRecoverySuggestion]]];
    }
    return [NSString stringWithString:msg];
}

@end
