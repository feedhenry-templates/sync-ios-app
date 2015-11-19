# sync-ios-app 

```sync-ios-app``` is a simple shopping list app that works with its server side companion app: [Sync Cloud App](https://github.com/feedhenry-templates/sync-cloud). This template demos the usage of the synchronization framework provided by [fh-ios-sdk](https://github.com/feedhenry/fh-ios-sdk) and how you can integrate it with Core Data.

|                 | Project Info  |
| --------------- | ------------- |
| License:        | Apache License, Version 2.0  |
| Build:          | Embedded FH.framework  |
| Documentation:  | http://docs.feedhenry.com/v3/dev_tools/sdks/ios.html|

### Build

1. Clone this project

2. Populate ```SyncApp/fhconfig.plist``` with your values as explained [here](http://docs.feedhenry.com/v3/dev_tools/sdks/ios.html#ios-configure).

3. open SyncApp.xcodeproj

## Example Usage

### Start synchronization

In ```SyncApp/DataManager.m``` the synchronization loop is started.
```
    FHSyncConfig* conf = [[FHSyncConfig alloc] init];
    conf.syncFrequency = 30;
    conf.notifySyncStarted = YES;
    conf.notifySyncCompleted = YES;
    ...
     FHSyncClient* syncClient = [FHSyncClient getInstance];
    [syncClient initWithConfig:conf];   // [1]
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncMessage:) name:kFHSyncStateChangedNotification object:nil]; // [2]
    [syncClient manageWithDataId:@"shoopingList" AndConfig:nil AndQuery:[NSDictionary dictionary]];  // [3]
```
[1] Initialize with sync configuration.

[2] Register to listen to ```kFHSyncStateChangedNotification``` event. Trigger ```onSyncMessage:``` as a callback.

[3] Initialize a sync client for a given dataset.

### Listening to sync notification to hook in 
In ```SyncApp/DataManager.m``` the method ```onSyncMessage``` is your callback method on sync events.

```
- (void) onSyncMessage:(NSNotification*) note
{
    FHSyncNotificationMessage* msg = (FHSyncNotificationMessage*) [note object];

    if([msg.code isEqualToString:REMOTE_UPDATE_APPLIED_MESSAGE]) {
        // Add UI / business code
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppDataUpdatedNotification object:nil];
}
```
