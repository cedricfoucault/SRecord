//
//  SRecordMenuViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 5/26/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SRecordMenuViewController.h"
#import "EditSentencesViewController.h"
#import "SessionViewController.h"

@interface SRecordMenuViewController ()

- (NSString *)sentencesFilePath;
- (NSArray *)loadSentences;

@end

@implementation SRecordMenuViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)sentencesFilePath {
    static NSString *path = nil;
    if (path == nil) {
        // retrieve document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        // get filepath in this directory
        path = [documentsPath stringByAppendingPathComponent:@"sentences"];
    }
    return path;
}

- (NSArray *)loadSentences {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self sentencesFilePath]];
}

- (void)saveSentences:(NSArray *)sentences {
    [NSKeyedArchiver archiveRootObject:sentences toFile:[self sentencesFilePath]];
}


- (NSArray *)sentences {
    NSArray *sentences = [self loadSentences];
    if (sentences == nil) {
        sentences = [NSArray array];
    }
    return sentences;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"EditSentences"]) {
        UINavigationController *editNavigationViewController = [segue destinationViewController];
        EditSentencesViewController *editViewController = (EditSentencesViewController *) editNavigationViewController.topViewController;
        editViewController.sentences = [NSMutableArray arrayWithArray:self.sentences];
    } else if ([[segue identifier] isEqualToString:@"StartSession"]) {
        SessionViewController *sessionController = [segue destinationViewController];
        [sessionController startNewSessionWithSentences:self.sentences];
    }
}

- (IBAction)done:(UIStoryboardSegue *)segue {
    if ([[segue identifier] isEqualToString:@"DoneEdit"]) {
        // save/get the new sentences
        EditSentencesViewController *editViewController = [segue sourceViewController];
        NSLog(@"%@", [editViewController.sentences componentsJoinedByString:@", "]);
        [self saveSentences:editViewController.sentences];
        
        // dismiss previous edit view controller
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)cancel:(UIStoryboardSegue *)segue {
    if ([[segue identifier] isEqualToString:@"CancelEdit"]) {
        // dismiss previous edit view controller
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

@end
