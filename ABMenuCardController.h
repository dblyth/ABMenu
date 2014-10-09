//
//  ABMenuCardController.h
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>

#import "ABMenuInfoTableView.h"
#import "ABMenuTextView.h"

#define kABCopyMenuItem                 1
#define kABSendEmailMenuItem            3
#define kABSendInstantMessageMenuItem   4
#define kABGoToLocationMenuItem         5
#define kABMapAddressMenuItem           6
#define kABEditCardMenuItem             8

#define kValueDictKey   @"value"
#define kTypeDictKey    @"type"
#define kLabelDictKey   @"label"

#define kABControllerClosedNotification @"ABControllerClosed"

@interface ABMenuCardController : NSWindowController
{
    IBOutlet NSTextField* nameField;
    IBOutlet NSTextField* titleField;
    IBOutlet ABMenuInfoTableView* infoList;
    IBOutlet NSImageView* iconView;
    IBOutlet ABMenuTextView* noteView;
    IBOutlet NSButton* disclosureButton;
    
    IBOutlet NSPanel *hudPanel;
    IBOutlet NSPanel *normalPanel;
    IBOutlet NSView *infoView;
    
    IBOutlet NSMenu *actionMenu;
    IBOutlet NSPopUpButton *actionButton;
    
    ABPerson *representedPerson;
    NSMutableArray *propertyArray; // Array of NSDictionaries
}

-(id)initWithContact:(ABPerson *)contact;
-(void)setCardAlpha:(float)newAlpha;
-(void)buildCard;
-(void)validateActionMenu;
-(void)addPropertiesToTable;
-(void)clearProperties;
-(NSString *)scanLabel:(NSString *)label;
-(NSString *)scanIMType:(NSString *)type;
-(NSString *)buildAddress:(NSDictionary *)addressDict;
-(BOOL)isIMProperty:(NSString *)type;
-(ABPerson *)representedPerson;
-(void)addMultiValueProperty:(NSString *)property;

-(void)closeCardIfNecessary;

-(void)doubleClick:(id)sender;
-(IBAction)editContact:(id)sender;
-(IBAction)copy:(id)sender;
-(IBAction)sendEmail:(id)sender;
-(IBAction)goToLocation:(id)sender;
-(IBAction)mapAddress:(id)sender;
-(IBAction)instantMessage:(id)sender;
-(IBAction)noteDisclosureClick:(id)sender;

@end
