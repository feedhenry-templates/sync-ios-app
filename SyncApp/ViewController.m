/*
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "ViewController.h"
#import <FH/FH.h>
#import <FH/FHSyncClient.h>
#import <FH/FHSyncNotificationMessage.h>
#import <FH/FHResponse.h>

@interface ViewController ()
{
  FHSyncClient* _fhSyncClient;
}
@end

#define DATAID @"myShoppingList"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  [FH initWithSuccess:^(FHResponse* fhres){
    [self startSyncClient];
    
    
  } AndFailure:^(FHResponse* fhres){
    NSLog(@"Init Failed. Error: %@", fhres.error);
    [self startSyncClient];
  }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startSyncClient
{
  _fhSyncClient = [FHSyncClient getInstance];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncMessage:) name:kFHSyncStateChangedNotification object:nil];
  FHSyncConfig* conf = [[FHSyncConfig alloc] init];
  conf.notifySyncStarted = YES;
  conf.notifySyncCompleted = YES;
  conf.notifyRemoteUpdateApplied = YES;
  conf.notifyRemoteUpdateFailed = YES;
  conf.notifyLocalUpdateApplied = YES;
  [_fhSyncClient initWithConfig:conf];
  [_fhSyncClient manageWithDataId:DATAID AndConfig:nil AndQuery:[NSDictionary dictionary]];
}

- (void) onSyncMessage:(NSNotification*) note
{
  FHSyncNotificationMessage* msg = (FHSyncNotificationMessage*) [note object];
  NSLog(@"Got notification %@", msg);
  NSString* code = msg.code;
  if([code isEqualToString:SYNC_COMPLETE_MESSAGE]){
    NSDictionary* data = [_fhSyncClient listWithDataId:DATAID];
    [self performSelectorOnMainThread:@selector(setResultText:) withObject:data waitUntilDone:NO];
  }
}

- (void) setResultText:(NSDictionary*) data
{
  if(data){
    resultView.text = [NSString stringWithFormat:@"%f \n %@", [[NSDate date] timeIntervalSince1970], [data JSONString]];
  }
}

- (IBAction)selectCreateButton:(id)sender
{
  NSMutableDictionary* data = [NSMutableDictionary dictionary];
  NSString* str = uidField.text;
  [data setObject:str forKey:@"name"];
  [data setObject:[[NSDate date] description] forKey:@"created"];
  [_fhSyncClient createWithDataId:DATAID AndData:data];
}

- (IBAction)selectReadButton:(id)sender
{
  NSString* uid = uidField.text;
  if(![uid isEqualToString:@""]){
    NSDictionary* data = [_fhSyncClient readWithDataId:DATAID AndUID:uid];
    [self setResultText:data];
  }
}

- (IBAction)selectUpdateButton:(id)sender
{
  NSString* uid = uidField.text;
  if(![uid isEqualToString:@""]){
    NSMutableDictionary* data = [NSMutableDictionary dictionary];
    NSString* str = [NSString stringWithFormat:@"Data updated by ios client %f", [[NSDate date] timeIntervalSince1970]];
    [data setObject:str forKey:@"name"];
    [data setObject:[[NSDate date] description] forKey:@"created"];
    [_fhSyncClient updateWithDataId:DATAID AndUID:uid AndData:data];
  }
}

- (IBAction)selectDeleteButton:(id)sender
{
  NSString* uid = uidField.text;
  if(![uid isEqualToString:@""]){
    [_fhSyncClient deleteWithDataId:DATAID AndUID:uid];
  }
}

@end
