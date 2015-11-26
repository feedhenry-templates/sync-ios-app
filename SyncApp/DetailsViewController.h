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

#import <UIKit/UIKit.h>
#import "ShoppingItem.h"
#import "DataManager.h"

@interface DetailsViewController : UIViewController
{
  IBOutlet UITextField* nameField;
  IBOutlet UITextField* createdField;
  ShoppingItem* _item;;
  IBOutlet UILabel* createLabel;
  NSString* action;
  DataManager* dataManager;
}

@property (nonatomic, retain) IBOutlet UITextField* nameField;
@property (nonatomic, retain) IBOutlet UITextField* createdField;
@property (nonatomic, retain) IBOutlet UILabel* createLabel;
@property (nonatomic, retain) DataManager* dataManager;
@property (nonatomic, retain) UIButton* saveButton;
@property (nonatomic, retain) UIButton* deleteButton;
@property (nonatomic, retain) ShoppingItem* item;
@property (nonatomic, retain) NSString* action;

- (IBAction)saveItem:(id)sender;

-(BOOL) textFieldShouldReturn:(UITextField *)textField;
-(void)dismissKeyboard;
@end
