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

@interface MenuViewController ()

- (void) updateConnectionStatusLabel;

@end

@implementation MenuViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        self.connectionManager = [[SCConnectionManager alloc] init];
    }
    return self;
}

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
            if ([self.connectionManager isLoggedIn]) {
                [self.connectionManager logOut];
                [self updateConnectionStatusLabel];
            } else {
                [self.connectionManager presentLoginViewControllerWithPresenter:self.sidePanelController completion:^() {
                    [self updateConnectionStatusLabel];
                }];
            }
//            [self.sidePanelController toggleLeftPanel:self];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
    }
//    [self.sidePanelController toggleLeftPanel:self];
//    [self.sidePanelController showCenterPanelAnimated:YES];
}

- (void) updateConnectionStatusLabel {
    if ([self.connectionManager isLoggedIn]) {
        self.connectionStatusLabel.text = @"Log Out";
    } else {
        self.connectionStatusLabel.text = @"Log In";
    }
}

@end
