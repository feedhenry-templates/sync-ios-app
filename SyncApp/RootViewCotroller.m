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

#import "RootViewCotroller.h"
#import <CoreData/CoreData.h>
#import "ShoppingItem.h"
#import "DetailsViewController.h"

@interface RootViewCotroller ()

@end

@implementation RootViewCotroller

@synthesize items;
@synthesize dataManager;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.editButtonItem.enabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDataUpdated:) name:kAppDataUpdatedNotification object:nil];
}

- (void) viewDidUnload
{
    self.items = nil;
}

- (void) onDataUpdated:(NSNotification*) note
{
    self.items = [dataManager listItems];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    ShoppingItem* item = [items objectAtIndex:indexPath.row];
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", item.name, [dateFormatter stringFromDate:item.created]];
    return cell;
}


#pragma mark - Table view delegate
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ShoppingItem* item = nil;
    if ([[segue identifier] isEqualToString:@"showExistingItemDetails"]) {
        item = [self.items objectAtIndex:[self.tableView indexPathForCell:sender].row];
        DetailsViewController* dest = [segue destinationViewController];
        dest.item = item;
        dest.dataManager = self.dataManager;
        dest.action = @"update";
    } else if ([[segue identifier] isEqualToString:@"showNewItemDetails"]) {
        item = [dataManager getItem];
        DetailsViewController* dest = [segue destinationViewController];
        dest.item = item;
        dest.dataManager = self.dataManager;
        dest.action = @"create";
    }
    
}

// Swipe to delete.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [dataManager deleteItem:items[indexPath.row]];
        [tableView reloadData];
    }
}

@end
