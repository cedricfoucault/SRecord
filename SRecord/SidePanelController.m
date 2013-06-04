//
//  SidePanelViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/2/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SidePanelController.h"
#import "MenuViewController.h"
#import "SentencesController.h"
#import <SCSoundCloud.h>

@implementation SidePanelController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.sentencesController = [[SentencesController alloc] init];
        self.bounceOnCenterPanelChange = NO;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.menuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MenuViewController"];
    self.menuViewController.sidePanelController = self;
    self.homeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];
    self.sentencesViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditSentencesViewController"];
    [self setLeftPanel:self.menuViewController];
    [self setCenterPanel:self.homeViewController];
}

@end
