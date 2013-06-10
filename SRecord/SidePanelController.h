//
//  SidePanelViewController.h
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JASidePanelController.h>
@class MenuViewController;
@class SentencesManager;

@interface SidePanelController : JASidePanelController

@property (strong, nonatomic) UIViewController *homeViewController;
@property (strong, nonatomic) MenuViewController *menuViewController;
@property (strong, nonatomic) UIViewController *sentencesViewController;
@property (strong, nonatomic) UIViewController *pushViewController;

@end
