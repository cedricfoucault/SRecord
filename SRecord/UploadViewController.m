//
//  UploadViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/8/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "UploadViewController.h"
#import "UploadController.h"
#import "SessionRecordingsManager.h"

@interface UploadViewController () <UploadControllerDelegate, UITextFieldDelegate, UIActionSheetDelegate>

@property (copy, nonatomic) NSString *SCSetName;
@property (strong, nonatomic) UploadController *uploadController;
@property (weak, nonatomic) IBOutlet UITextField *SCSetNameInput;

- (void)customInit;
- (void)resetViews;
- (IBAction)okButtonTapped;
- (IBAction)dontUploadButtonTapped:(UIButton *)sender;

@end

@implementation UploadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self customInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        [self customInit];
    }
    return self;
}

- (void)customInit {
    self.uploadController = [[UploadController alloc] initWithDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self resetViews];
}

- (void)resetViews {
    self.SCSetNameInput.text = self.defaultSCSetName;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDefaultSCSetName:(NSString *)name {
    if (![_defaultSCSetName isEqualToString:name]) {
        _defaultSCSetName = [NSString stringWithString:name];
        self.SCSetName = self.defaultSCSetName;
    }
}

- (IBAction)okButtonTapped {
    [self.uploadController uploadTracksWithRecordings:self.recordings SCSetName:self.SCSetName];
}

- (IBAction)dontUploadButtonTapped:(UIButton *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Delete recordings"
                                                    otherButtonTitles:@"Save for later", nil];
    [actionSheet showFromRect:sender.frame inView:self.view animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet destructiveButtonIndex] == buttonIndex) {
        [self performSegueWithIdentifier:@"CancelUploadSegue" sender:self];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Save for later"]) {
        [SessionRecordingsManager saveSessionWithDate:self.sessionDate recordings:self.recordings SCSetName:self.SCSetName];
        [self performSegueWithIdentifier:@"CancelUploadSegue" sender:self];
    }
}

- (void)didCancelUploading {
    // save recordings for possible later uploading
    [SessionRecordingsManager saveSessionWithDate:self.sessionDate recordings:self.recordings SCSetName:self.SCSetName];
    [self performSegueWithIdentifier:@"CancelUploadSegue" sender:self];
}

- (void)didFinishUploading {
    [self performSegueWithIdentifier:@"DoneUploadSegue" sender:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.SCSetNameInput) {
        if ([self.SCSetNameInput.text length] > 0) {
            self.SCSetName = self.SCSetNameInput.text;
        } else {
            self.SCSetName = self.defaultSCSetName;
            self.SCSetNameInput.text = self.defaultSCSetName;
        }
        [textField resignFirstResponder];
    }
    return YES;
}

@end
