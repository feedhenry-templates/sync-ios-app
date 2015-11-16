/*
 * JBoss, Home of Professional Open Source.
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

#import "DataManager.h"
#import <FH/FHSyncNotificationMessage.h>
#import "ShoppingItem.h"

@implementation DataManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize syncClient = _syncClient;

- (void) start
{
  FHSyncConfig* conf = [[FHSyncConfig alloc] init];
  conf.notifySyncStarted = YES;
  conf.notifySyncCompleted = YES;
  conf.notifyRemoteUpdateApplied = YES;
  conf.notifyRemoteUpdateFailed = YES;
  conf.notifyLocalUpdateApplied = YES;
  [_syncClient initWithConfig:conf];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncMessage:) name:kFHSyncStateChangedNotification object:nil];
  [self.syncClient manageWithDataId:DATA_ID AndConfig:nil AndQuery:[NSDictionary dictionary]];
}

- (void) onSyncMessage:(NSNotification*) note
{
  FHSyncNotificationMessage* msg = (FHSyncNotificationMessage*) [note object];
  NSLog(@"Got notification %@", msg);
  NSString* code = msg.code;
  if([code isEqualToString:SYNC_COMPLETE_MESSAGE]){
    NSMutableDictionary* data = [[self.syncClient listWithDataId:DATA_ID] mutableCopy];
    NSMutableArray* processed = [NSMutableArray array];
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"ShoppingItem"];
    NSArray* alldata = [self.managedObjectContext executeFetchRequest:request error:nil];
    for (int i=0; i<alldata.count; i++) {
      ShoppingItem* item = (ShoppingItem*)[alldata objectAtIndex:i];
      if (item && item.uid) {
        [processed addObject:item.uid];
      }
      if ([data objectForKey:item.uid]) {
        //data already exists
        NSDictionary* syncData = [[data objectForKey:item.uid] objectForKey:@"data"];
        item.name = [syncData objectForKey:@"name"];
        NSNumber* create = [NSNumber numberWithLongLong:[[syncData objectForKey:@"created"] longLongValue]/1000];
        item.created = [NSDate dateWithTimeIntervalSince1970:[create doubleValue]];
        NSLog(@"Update record: %@", item);
      } else {
        //data deleted
        [self.managedObjectContext deleteObject:item];
        NSLog(@"Delete record: %@", item);
      }
    }
    
    [data removeObjectsForKeys:processed]; //what left will be new data
    
    [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop){
      NSDictionary* datasource = [obj objectForKey:@"data"];
      ShoppingItem* record = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:[self managedObjectContext]];
      record.uid = key;
      record.name = [datasource objectForKey:@"name"];
      NSNumber* create = [NSNumber numberWithLongLong:[[datasource objectForKey:@"created"] longLongValue]/1000];
      record.created = [NSDate dateWithTimeIntervalSince1970:[create doubleValue]];
      NSLog(@"Creating record: %@", record);
    }];
    
    NSError *error;
    if(![self.managedObjectContext save:&error]){
      NSLog(@"Error when saving record: %@", [error localizedDescription]);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppDataUpdatedNotification object:nil];
  }
}

- (NSArray*) listItems
{
  NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"ShoppingItem"];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO];
  NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
  [request setSortDescriptors:sortDescriptors];
  return [self.managedObjectContext executeFetchRequest:request error:nil];
}

- (ShoppingItem*) createItem:(ShoppingItem*) shoppingItem
{
  NSDate* now = [NSDate date];
  NSMutableDictionary* data = [NSMutableDictionary dictionary];
  [data setObject:shoppingItem.name forKey:@"name"];
  [data setObject:[NSNumber numberWithLongLong:[now timeIntervalSince1970]*1000] forKey:@"created"];
  [_syncClient createWithDataId:DATA_ID AndData:data];
  return shoppingItem;
}

- (ShoppingItem*) updateItem:(ShoppingItem*) shoppingItem
{
  NSMutableDictionary* data = [NSMutableDictionary dictionary];
  [data setObject:shoppingItem.name forKey:@"name"];
  [data setObject:[NSNumber numberWithLongLong:[shoppingItem.created timeIntervalSince1970]*1000] forKey:@"created"];
  [_syncClient updateWithDataId:DATA_ID AndUID:shoppingItem.uid AndData:data];
  return shoppingItem;
}

- (ShoppingItem*) deleteItem:(ShoppingItem*) shoppingItem
{
  [_syncClient deleteWithDataId:DATA_ID AndUID:shoppingItem.uid];
  return shoppingItem;
}

- (ShoppingItem*) getItem
{
  return [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:[self managedObjectContext]];
}
@end
