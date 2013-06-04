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

@interface MenuViewController ()

- (void) updateConnectionStatusLabel;

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
                void (^login_handler)(NSError *) = ^(NSError *error) {
                    if (error) {
                        if (SC_CANCELED(error)) {
                            // login was canceled, do nothing
                        } else if ([[error domain] isEqualToString:NSURLErrorDomain]) {
                            NSString *errorMsg;
                            switch ([error code]) {
                                case NSURLErrorCannotFindHost:
                                    errorMsg = NSLocalizedString(@"Cannot find specified host. Retype URL.", nil);
                                    break;
                                case NSURLErrorCannotConnectToHost:
                                    errorMsg = NSLocalizedString(@"Cannot connect to specified host. Server may be down.", nil);
                                    break;
                                case NSURLErrorNotConnectedToInternet:
                                    errorMsg = NSLocalizedString(@"Cannot connect to the internet. Service may not be available.", nil);
                                    break;
                                default:
                                    errorMsg = [error localizedDescription];
                                    break;
                            }
                        }
                    } else { // no error
                        [self updateConnectionStatusLabel];
                        if ([SCConnectionManager isLoggedIn]) {
                            [SVProgressHUD showSuccessWithStatus:@"Logged in"];
                        }
                    }
                };
                [SCConnectionManager presentLoginViewControllerWithPresenter:self.sidePanelController
                                                                  completion:login_handler];
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

@end
