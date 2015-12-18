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

#import "DataManager.h"
#import <FH/FHSyncNotificationMessage.h>
#import "ShoppingItem.h"

@implementation DataManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize syncClient = _syncClient;

- (void) start
{
    FHSyncConfig* conf = [[FHSyncConfig alloc] init];
    conf.syncFrequency = 30;
    conf.notifySyncStarted = YES;
    conf.notifySyncCompleted = YES;
    conf.notifySyncFailed = YES;
    conf.notifyRemoteUpdateApplied = YES;
    conf.notifyRemoteUpdateFailed = YES;
    conf.notifyLocalUpdateApplied = YES;
    conf.notifyDeltaReceived = YES;
    conf.crashCountWait = 0;
    [_syncClient initWithConfig:conf];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncMessage:) name:kFHSyncStateChangedNotification object:nil];
    [self.syncClient manageWithDataId:DATA_ID AndConfig:nil AndQuery:[NSDictionary dictionary]];
}


- (void) onSyncMessage:(NSNotification*) note
{
    FHSyncNotificationMessage* msg = (FHSyncNotificationMessage*) [note object];
    NSLog(@"Got notification %@", msg);
    NSString* code = msg.code;
    //when a new record is created for the first time, the uid is a temporary one and will change once the data is synced to the cloud.
    //Here we listen for the REMOTE_UPDATE_APPLIED_MESSAGE notification and update the data record with the updated uid
    if([code isEqualToString:REMOTE_UPDATE_APPLIED_MESSAGE]) {
        NSString* message = msg.message;
        NSDictionary* obj = [message objectFromJSONString];
        if ([[obj valueForKey:@"action"] isEqualToString:@"create"]) {
            NSString* oldUid = [obj valueForKey:@"hash"];
            NSString* newUid = [obj valueForKey:@"uid"];
            NSLog(@"creation applied, old uid = %@ and new uid = %@", oldUid, newUid);
            ShoppingItem* item = [self findItemByUid:oldUid];
            if (item) {
                item.uid = newUid;
            }
            if ([self.managedObjectContext hasChanges]) {
                NSError* saveError;
                if(![[self managedObjectContext] save:&saveError]){
                    NSLog(@"Failed to update uid from %@ to %@ due to error %@", oldUid, newUid, [saveError localizedDescription]);
                }
            }
        }
    }
    
    if (([code isEqualToString:LOCAL_UPDATE_APPLIED_MESSAGE] || [code isEqualToString:DELTA_RECEIVED_MESSAGE]) && msg.UID) {
        NSString* action = [msg message];
        NSString* uid = [msg UID];
        if ([action isEqualToString:@"create"]) {
            ShoppingItem* existing = [self findItemByUid:uid];
            NSDictionary* data = [self.syncClient readWithDataId:DATA_ID AndUID:uid];
            NSDictionary* datasource = [data objectForKey:@"data"];
            if (!existing) {
                existing = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:[self managedObjectContext]];
                existing.uid = uid;
                NSNumber* create = [NSNumber numberWithLongLong:[[datasource objectForKey:@"created"] longLongValue]/1000];
                existing.created = [NSDate dateWithTimeIntervalSince1970:[create doubleValue]];
            }
            existing.name = [datasource objectForKey:@"name"];
        } else {
            ShoppingItem* item = [self findItemByUid:uid];
            if (item) {
                if([action isEqualToString:@"update"]) {
                    NSDictionary* data = [self.syncClient readWithDataId:DATA_ID AndUID:uid];
                    NSDictionary* updated = [data objectForKey:@"data"];
                    item.name = [updated valueForKey:@"name"];
                } else if ([action isEqualToString:@"delete"]) {
                    [[self managedObjectContext] deleteObject:item];
                }
            }
        }
        if ([self.managedObjectContext hasChanges]) {
            NSError* saveError;
            if(![self.managedObjectContext save:&saveError]){
                NSLog(@"Error when saving record: %@", [saveError localizedDescription]);
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppDataUpdatedNotification object:nil];
}

- (ShoppingItem*) findItemByUid:(NSString*) uid
{
    NSFetchRequest* request = [[NSFetchRequest alloc]init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"ShoppingItem" inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid == %@", uid];
    [request setPredicate:predicate];
    NSError* error;
    NSArray* results = [[self managedObjectContext] executeFetchRequest:request error:&error];
    if(!error){
        if ([results count] > 0) {
            ShoppingItem* item = [results objectAtIndex:0];
            return item;
        } else {
            return nil;
        }
    } else {
        NSLog(@"Error when lookup item with uid: %@, error: %@", uid, [error localizedDescription]);
        return nil;
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
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ShoppingItem" inManagedObjectContext:self.managedObjectContext];
    return [[ShoppingItem alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:nil];
}
@end
