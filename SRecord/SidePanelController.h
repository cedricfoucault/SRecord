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
@class SentencesController;

@interface SidePanelController : JASidePanelController

@property (strong, nonatomic) UIViewController *homeViewController;
@property (strong, nonatomic) MenuViewController *menuViewController;
@property (strong, nonatomic) UIViewController *sentencesViewController;
@property (strong, nonatomic) SentencesController *sentencesController;

@end
