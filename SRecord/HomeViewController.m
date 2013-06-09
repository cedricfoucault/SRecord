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
#import <SVProgressHUD.h>
#import "UITableViewCell+Checkable.h"

@interface HomeViewController ()
@property (weak, nonatomic) IBOutlet UITableView *sentencesTableView;
@property (strong, nonatomic) NSMutableSet *checkedIndices;

- (void)customInit;

@end

@implementation HomeViewController

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
    self.checkedIndices = [[NSCountedSet alloc] init];
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
    
    [cell setChecked:NO];
    for (NSIndexPath *checkedIndexPath in self.checkedIndices) {
        if ([indexPath compare:checkedIndexPath] == NSOrderedSame) {
            [cell setChecked:YES];
            break;
        }
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // deselect cell
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isChecked]) {
        [cell setChecked:NO];
        // Reflect uncheck in data model
        [self.checkedIndices removeObject:indexPath];
    } else {
        [cell setChecked:YES];
        // Reflect uncheck in data model
        [self.checkedIndices addObject:indexPath];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"StartSessionSegue"]) {
        SessionViewController *sessionController = [segue destinationViewController];
        // retrieve the sentences that were checked by the user
        NSMutableArray *checkedSentences = [[NSMutableArray alloc] init];
        NSArray *sentences = [SentencesController loadSentences];
        NSArray *sortDescrs = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"row" ascending:YES]];
        for (NSIndexPath *checkedIndexPath in [self.checkedIndices sortedArrayUsingDescriptors:sortDescrs]) {
            [checkedSentences addObject:[sentences objectAtIndex:checkedIndexPath.row]];
        }
        // init a new session
        [sessionController startNewSessionWithSentences:checkedSentences];
    }
}

- (IBAction)startPressed {
    if ([self.checkedIndices count] > 0) {
        [self performSegueWithIdentifier:@"StartSessionSegue" sender:self];
    } else {
        [SVProgressHUD showErrorWithStatus:@"No sentence selected"];
    }
}

- (IBAction)done:(UIStoryboardSegue *)segue {
}

- (IBAction)cancel:(UIStoryboardSegue *)segue {
}

@end
