//
//  SessionEndViewController.m
//  SRecord
//
//  Created by Cédric Foucault on 5/29/13.
//  Copyright (c) 2013 Cédric Foucault. All rights reserved.
//

#import "SessionEndViewController.h"
#import <SoundCloudAPI/SCAPI.h>
#import <SoundCloudUI/SCUI.h>
#import <OAuth2Client/NXOAuth2.h>
#import <OAuth2Client/NXOAuth2AccountStore.h>
#import "SRConstants.h"
#import "RecordingHandler.h"

@interface SessionEndViewController ()

- (void)uploadRecordingsWithEnumerator:(NSEnumerator *)enumerator;

@end

@implementation SessionEndViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        // Observe SC notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidChange:)
                                                     name:SCSoundCloudAccountDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFailToRequestAccess:)
                                                     name:SCSoundCloudDidFailToRequestAccessNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc; {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // login to soundcloud
    [self loginToSC];
    NSLog(@"login done");
    // upload
    [self startUploading];
}

- (void)loginToSC {
    if (![SCSoundCloud account]) {
        NSLog(@"try to login");
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:kSCAccountType
                                                                  username:kSRSoundCloudUsername
                                                                  password:kSRSoundCloudPassword];
//        [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
//            SCLoginViewController *loginViewController;
//            loginViewController = [SCLoginViewController loginViewControllerWithPreparedURL:preparedURL
//                                                                          completionHandler:^(NSError *error){
//                                                                              
//                                                                              if (SC_CANCELED(error)) {
//                                                                                  NSLog(@"Canceled!");
//                                                                              } else if (error) {
//                                                                                  NSLog(@"Ooops, something went wrong: %@", [error localizedDescription]);
//                                                                              } else {
//                                                                                  NSLog(@"Done!");
//                                                                              }
//                                                                              if (![SCSoundCloud account]) {
//                                                                                  NSLog(@"No SC account");
//                                                                              } else {
//                                                                                  NSLog(@"Yes SC account");
//                                                                              }
//                                                                          }];
//            
//            [self presentViewController:loginViewController animated:YES completion:nil];
//        
//        }];
        if (![SCSoundCloud account]) {
            NSLog(@"No SC account: login failed");
        }
    }
}

- (void)startUploading {
    NSLog(@"Start uploading");
    // upload recording by recording
    [self uploadRecordingsWithEnumerator:[self.recordings objectEnumerator]];
}

- (void)uploadRecordingsWithEnumerator:(NSEnumerator *)enumerator {
    // get the next recording to upload
    RecordingHandler *rec = [enumerator nextObject];
    if (rec) {
        // set parameters for the track to upload
        SCAccount *account = [SCSoundCloud account];
        BOOL private = YES;
        NSString *trackTitle = [NSString stringWithFormat:@"%@ S%04d", rec.transcript, rec.sessionNo];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    rec.fileURL, @"track[asset_data]",
                                    trackTitle, @"track[title]",
                                    (private) ? @"private" : @"public", @"track[sharing]", //a BOOL
                                    @"recording", @"track[type]",
                                    @"description", @"A sample recorded from session ",
                                    //             sharingConnections, @"track[post_to][][id]", //array of id strings
                                    nil];
        // send POST request to /tracks
        [SCRequest performMethod:SCRequestMethodPOST
                      onResource:[NSURL URLWithString:@"https://api.soundcloud.com/tracks.json"]
                 usingParameters:parameters
                     withAccount:account
          sendingProgressHandler:^(unsigned long long bytesSent, unsigned long long bytesTotal){
              NSLog(@"%f%%", (bytesSent * 100.0) / bytesTotal);
          }
                 responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                     if (error) {
                         NSLog(@"Ooops, something went wrong! %@", [error localizedDescription]);
                     } else {
                         if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                             NSLog(@"Expecting a NSURLHTTPResponse.");
                         } else {
                             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                             if ([httpResponse statusCode] >= 200 && [httpResponse statusCode] < 300) {
                                 // Ok, the upload succeed
                                 // Parse the response if you want to have the info of the uploaded track.
                                 NSLog(@"Uploaded %@.", [[rec.fileURL absoluteString] lastPathComponent]);
                             }
                         }
                     }
                     // upload next recording
                     [self uploadRecordingsWithEnumerator:enumerator];
                 }];
    }
}

- (void)accountDidChange:(NSNotification *)aNotification; {
    if (![SCSoundCloud account]) {
        // Login again
        [self loginToSC];
    }
}

- (void)didFailToRequestAccess:(NSNotification *)aNotification; {
    NSError *error = [[aNotification userInfo] objectForKey:NXOAuth2AccountStoreErrorKey];
    NSLog(@"Requesting access to SoundCloud did fail with error: %@", [error localizedDescription]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
