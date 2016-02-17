# sync-ios-app [![Build Status](https://travis-ci.org/feedhenry-templates/sync-ios-app.png)](https://travis-ci.org/feedhenry-templates/sync-ios-app)

Author: Corinne Krych   
Level: Intermediate  
Technologies: Objective-C, iOS, RHMAP, CocoaPods.
Summary: A demonstration of how to synchronize a single collection with RHMAP. 
Community Project : [Feed Henry](http://feedhenry.org)
Target Product: RHMAP  
Product Versions: RHMAP 3.7.0+   
Source: https://github.com/feedhenry-templates/sync-ios-app  
Prerequisites: fh-ios-sdk : 3.+, Xcode : 7.2+, iOS SDK : iOS7+, CocoaPods: 0.39+

## What is it?

This application manages items in a collection that is synchronized with a remote RHMAP cloud application.  The user can create, update, and delete collection items.  Refer to [SyncApp/fhconfig.plist](SyncApp/fhconfig.plist) for the delevant pieces of code and configuraiton.

If you do not have access to a RHMAP instance, you can sign up for a free instance at [https://openshift.feedhenry.com/](https://openshift.feedhenry.com/).

## How do I run it?  

### RHMAP Studio

This application and its cloud services are available as a project template in RHMAP as part of the "Sync Framework Project" template.

### Local Clone (ideal for Open Source Development)
If you wish to contribute to this template, the following information may be helpful; otherwise, RHMAP and its build facilities are the preferred solution.

## Build instructions

1. Clone this project

2. Populate ```SyncApp/fhconfig.plist``` with your values as explained [here](http://docs.feedhenry.com/v3/dev_tools/sdks/ios.html#ios-configure).

3. Run ```pod install``` 

4. Open SyncApp.xcworkspace

5. Run the project
 
## How does it work?

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
