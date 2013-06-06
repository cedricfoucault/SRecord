//
//  SRecordMenuViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 5/26/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "HomeViewController.h"
#import "SessionViewController.h"
#import "SentencesController.h"

@interface HomeViewController ()
@property (weak, nonatomic) IBOutlet UITableView *sentencesTableView;

@end

@implementation HomeViewController

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.sentencesTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[SentencesController loadSentences] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Retrieve the cell
    static NSString *DefaultCellIdentifier = @"BasicCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *sentence = [[SentencesController loadSentences] objectAtIndex:indexPath.row];
    if (![cell.textLabel.text isEqualToString:sentence]) {
        cell.textLabel.text = sentence;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Sentences to record";
    } else { // should not happen
        return @"";
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([[segue identifier] isEqualToString:@"EditSentences"]) {
//        UINavigationController *editNavigationViewController = [segue destinationViewController];
//        EditSentencesViewController *editViewController = (EditSentencesViewController *) editNavigationViewController.topViewController;
//        editViewController.sentences = [NSMutableArray arrayWithArray:self.sentences];
//    } else
    if ([[segue identifier] isEqualToString:@"StartSession"]) {
        SessionViewController *sessionController = [segue destinationViewController];
        [sessionController startNewSessionWithSentences:[SentencesController loadSentences]];
    }
}

- (IBAction)done:(UIStoryboardSegue *)segue {
//    if ([[segue identifier] isEqualToString:@"DoneEdit"]) {
//        // save/get the new sentences
//        EditSentencesViewController *editViewController = [segue sourceViewController];
//        NSLog(@"%@", [editViewController.sentences componentsJoinedByString:@", "]);
//        [self saveSentences:editViewController.sentences];
//        
//        // dismiss previous edit view controller
//        [self dismissViewControllerAnimated:YES completion:NULL];
//    }
}

- (void)cancel:(UIStoryboardSegue *)segue {
//    if ([[segue identifier] isEqualToString:@"CancelEdit"]) {
//        // dismiss previous edit view controller
//        [self dismissViewControllerAnimated:YES completion:NULL];
//    }
}

@end
