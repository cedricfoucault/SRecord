//
//  MenuViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SidePanelController;
@class SCConnectionManager;

@interface MenuViewController : UITableViewController

@property (weak, nonatomic) SidePanelController *sidePanelController;
@property (strong, nonatomic) SCConnectionManager *connectionManager;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;

@end
