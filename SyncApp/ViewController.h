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

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
{
  IBOutlet UIButton* createButton;
  IBOutlet UIButton* readButton;
  IBOutlet UIButton* updateButton;
  IBOutlet UIButton* deleteButton;
  IBOutlet UITextField* uidField;
  IBOutlet UITextView* resultView;
}

- (IBAction)selectCreateButton:(id)sender;
- (IBAction)selectReadButton:(id)sender;
- (IBAction)selectUpdateButton:(id)sender;
- (IBAction)selectDeleteButton:(id)sender;

@end
