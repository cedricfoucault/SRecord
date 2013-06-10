//
//  SavedRecordingsViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 6/9/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SavedRecordingsViewController.h"
#import "SessionRecordingsManager.h"
#import "SessionHandler.h"
#import "UploadController.h"

static NSInteger trashActionSheetTag = 0;
static NSInteger uploadActionSheetTag = 1;

@interface SavedRecordingsViewController () <UIActionSheetDelegate, UploadControllerDelegate>


@property (strong, nonatomic) NSMutableSet *checkedIndices;
@property (strong, nonatomic) UploadController *uploadController;
@property (strong, nonatomic) NSMutableArray *remainingUploads;
@property (strong, nonatomic) SessionHandler *currentUpload;

- (void)customInit;
- (void)cell:(UITableViewCell *)cell setChecked:(BOOL)isChecked;
- (NSString *)cellTextWithTitle:(NSString *)title checked:(BOOL)isChecked;
- (BOOL)cellAtIndexPathIsChecked:(NSIndexPath *)indexPath;
- (IBAction)actionButtonTapped:(UIBarButtonItem *)sender;
- (IBAction)trashButtonTapped:(UIBarButtonItem *)sender;
- (void)uploadRemaining;
- (SessionHandler *)popUpload;

@end

@implementation SavedRecordingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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
    self.checkedIndices = [[NSMutableSet alloc] init];
    self.uploadController = [[UploadController alloc] initWithDelegate:self];
    self.remainingUploads = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[SessionRecordingsManager savedSessions] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SessionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    SessionHandler *session = [[SessionRecordingsManager savedSessions] objectAtIndex:indexPath.row];
    // determine if checked or not
    BOOL checked = [self cellAtIndexPathIsChecked:indexPath];
    // set title text
    NSString *titleText = [self cellTextWithTitle:session.SCSetName checked:checked];
    if (![cell.textLabel.text isEqualToString:titleText]) {
        cell.textLabel.text = titleText;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // deselect cell
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([self cellAtIndexPathIsChecked:indexPath]) {
        [self cell:cell setChecked:NO];
        // Reflect uncheck in data model
        [self.checkedIndices removeObject:indexPath];
    } else {
        [self cell:cell setChecked:YES];
        // Reflect uncheck in data model
        [self.checkedIndices addObject:indexPath];
    }
}

- (IBAction)actionButtonTapped:(UIBarButtonItem *)sender {
    UIActionSheet *uploadActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:@"Upload all", @"Upload selected", nil];
    uploadActionSheet.tag = uploadActionSheetTag;
    [uploadActionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)trashButtonTapped:(UIBarButtonItem *)sender {
    UIActionSheet *trashActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:@"Delete all"
                                                         otherButtonTitles:@"Delete selected", nil];
    trashActionSheet.tag = trashActionSheetTag;
    [trashActionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == uploadActionSheetTag) { // trash action
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Upload all"]) {
            [self.remainingUploads removeAllObjects];
            // get all sessions to upload
            [self.remainingUploads setArray:[SessionRecordingsManager savedSessions]];
            // reset selected indices
            [self.checkedIndices removeAllObjects];
            // start uploading
            [self uploadRemaining];
            
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Upload selected"]) {
            [self.remainingUploads removeAllObjects];
            // get selected indices in sorted order
            NSArray *sortDescrs = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"row" ascending:YES]];
            for (NSIndexPath *indexPath in [self.checkedIndices sortedArrayUsingDescriptors:sortDescrs]) {
                SessionHandler *session = [[SessionRecordingsManager savedSessions] objectAtIndex:indexPath.row];
                [self.remainingUploads addObject:session];
            }
            // reset selected indices
            [self.checkedIndices removeAllObjects];
            [self.tableView reloadData];
            // start uploading
            [self uploadRemaining];
        }
    } else if (actionSheet.tag == trashActionSheetTag) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete all"]) {
            for (SessionHandler *session in [SessionRecordingsManager savedSessions]) {
                [SessionRecordingsManager deleteSession:session];
            }
            // reset selected indices
            [self.checkedIndices removeAllObjects];
            [self.tableView reloadData];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete selected"]) {
            // get sessions to delete
            NSMutableArray *sessionsToDelete = [[NSMutableArray alloc] initWithCapacity:[self.checkedIndices count]];
            NSArray *sortDescrs = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"row" ascending:YES]];
            for (NSIndexPath *indexPath in [self.checkedIndices sortedArrayUsingDescriptors:sortDescrs]) {
                [sessionsToDelete addObject:[[SessionRecordingsManager savedSessions] objectAtIndex:indexPath.row]];
            }
            // delete them
            for (SessionHandler *session in sessionsToDelete) {
                [SessionRecordingsManager deleteSession:session];
            }
            NSArray *deleteIndices = [self.checkedIndices allObjects];
            // reset selected indices
            [self.checkedIndices removeAllObjects];
            // delete rows at selected indices
            [self.tableView deleteRowsAtIndexPaths:deleteIndices withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}



- (BOOL)cellAtIndexPathIsChecked:(NSIndexPath *)indexPath {
    BOOL checked = NO;
    for (NSIndexPath *checkedIndexPath in self.checkedIndices) {
        if ([indexPath compare:checkedIndexPath] == NSOrderedSame) {
            checked = YES;
            break;
        }
    }
    return checked;
}

- (void)cell:(UITableViewCell *)cell setChecked:(BOOL)isChecked {
    NSString *title = [cell.textLabel.text substringFromIndex:2];
    cell.textLabel.text = [self cellTextWithTitle:title checked:isChecked];
}

- (NSString *)cellTextWithTitle:(NSString *)title checked:(BOOL)isChecked {
    if (isChecked) {
        return [NSString stringWithFormat:@"\u2713 %@", title];
    } else {
        return [NSString stringWithFormat:@"\u2001 %@", title];
    }
}

- (void)didFinishUploading {
    [SessionRecordingsManager deleteSession:self.currentUpload];
    [self.tableView reloadData];
    [self uploadRemaining];
}

- (void)didCancelUploading {
    [self uploadRemaining];
}

- (void)uploadRemaining {
    if ([self.remainingUploads count] != 0) {
        self.currentUpload = [self popUpload];
        [self.uploadController uploadSession:self.currentUpload];
    }
}

- (SessionHandler *)popUpload {
    SessionHandler *session = [self.remainingUploads objectAtIndex:0];
    [self.remainingUploads removeObjectAtIndex:0];
    return session;
}

@end
