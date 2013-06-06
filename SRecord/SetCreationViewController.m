//
//  SetCreationViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/5/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SetCreationViewController.h"
#import "SRAlertViewDelegate.h"
#import <SVProgressHUD.h>
#import <SCAPI.h>

@interface SetCreationViewController ()

@property (strong, nonatomic) SRAlertViewDelegate *alertDelegate;

- (void)createSCSet;
- (void)done;

@end

@implementation SetCreationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.nameInfoLabel.text = [NSString stringWithFormat:@"Its default name is \"%@\".\n"
                               "If you want to give it a custom name instead, type it below.", self.defaultSetTitle];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.customName = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)okButtonTapped:(id)sender {
    [self createSCSet];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.customNameInput) {
        if (self.customNameInput.text) {
            self.customName = self.customNameInput.text;
        }
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)createSCSet {
    // set request parameters for the new set
    NSString *title = self.customName ? self.customName : self.defaultSetTitle;
    SCAccount *account = [SCSoundCloud account];
    BOOL private = YES;
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                title, @"playlist[title]",
                                (private) ? @"private" : @"public", @"playlist[sharing]", //a BOOL
                                self.tracksID, @"playlist[tracks][][id]",
                                nil];
    // init response handler
    void (^responseHandler)(NSURLResponse *, NSData *, NSError *);
    responseHandler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            // inform that the request failed
            [SVProgressHUD showErrorWithStatus:@"Request failed"];
            // quit
            [self done];
        } else {
            // inform that the request has succeeded
            [SVProgressHUD showSuccessWithStatus:@"Set created"];
            // quit
            [self done];
        }
    };
    // init progress handler
    void (^progressHandler) (unsigned long long, unsigned long long);
    progressHandler = ^(unsigned long long bytesSent, unsigned long long bytesTotal) {
        CGFloat progress = (double)bytesSent / bytesTotal;
        [SVProgressHUD showProgress:progress status:@"Creating set" maskType:SVProgressHUDMaskTypeBlack];
    };
    // set POST request to /playlists
    [SCRequest performMethod:SCRequestMethodPOST
                  onResource:[NSURL URLWithString:@"https://api.soundcloud.com/playlists.json"]
             usingParameters:parameters
                 withAccount:account
      sendingProgressHandler:progressHandler
             responseHandler:responseHandler];
}

- (void)done {
    [self performSegueWithIdentifier:@"DoneCreateSet" sender:self];
}

@end
