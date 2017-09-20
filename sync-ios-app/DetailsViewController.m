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

#import "DetailsViewController.h"
#import <UIKit/UIKit.h>

@interface DetailsViewController ()

@end

@implementation DetailsViewController

@synthesize createdField;
@synthesize nameField;
@synthesize item = _item;
@synthesize saveButton;
@synthesize dataManager;
@synthesize action;
@synthesize createLabel;
@synthesize deleteButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    if (nil != _item) {
        self.nameField.delegate = self;
        self.nameField.text = _item.name;
        
        static NSDateFormatter *dateFormatter = nil;
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        }
        
        if (_item.uid != nil && ![_item.uid isEqualToString:@""]) {
            self.createLabel.hidden = NO;
            self.createdField.hidden = NO;
            self.createdField.text = [dateFormatter stringFromDate:_item.created];
            
            self.deleteButton.hidden = NO;
            
        } else {
            self.createLabel.hidden = YES;
            self.createdField.hidden = YES;
            self.createdField.text = @"";
            
            self.deleteButton.hidden = YES;
        }
    }
}

- (void) setItem:(ShoppingItem *)anotherItem
{
    _item = anotherItem;
    NSLog(@"selected item is %@", anotherItem);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveItem:(id)sender
{
    NSString* name = self.nameField.text;
    if (nil == name || [name isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Name can not be empty" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    } else {
        _item.name = name;
        if ([self.action isEqualToString:@"create"]) {
            [dataManager createItem:_item];
        } else if([self.action isEqualToString:@"update"]) {
            [dataManager updateItem:_item];
        }
    }
    [(UINavigationController*)self.parentViewController popViewControllerAnimated:YES];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)dismissKeyboard
{
    [self.nameField resignFirstResponder];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [(UINavigationController*)self.parentViewController popViewControllerAnimated:YES];
}

@end
