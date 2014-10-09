//
//  ABMenuController.h
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABPeoplePickerView.h>
//#import <IOBluetooth/OBEX.h>
//#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import "ABMenuBonjourController.h"

#define kABUseHUDCardInterface @"ABUseHUDCardInterface"
#define kABPublishBonjourInfo @"ABPublishBonjourInfo"
#define kABShowBonjourContacts @"ABShowBonjourContacts"
#define kABNumRecentContacts @"ABNumRecentContacts"
#define kABRecentContactsArray @"ABRecentContactsArray"
#define kABWindowOpacity @"ABWindowOpacity"
#define kABShowGroupSubmenus @"ABShowGroupSubmenus"
#define kABShowUngroupedContacts @"ABShowUngroupedContacts"
#define kABShowAllRecords @"ABShowAllRecords"
#define kABSortIntoAlphabeticalSubMenus @"ABSortIntoAlphabeticalSubMenus"
#define kABMapAddressSite @"AbMapAddressSite"
#define kABSortByLastName @"ABSortByLastName"
#define kABAutoOpenNotes @"ABAutoOpenNotes"
#define kABAutoCloseAfterAction @"ABAutoCloseAfterAction"

#define kGoogleMaps     0
#define kLiveMaps       1
#define kYahooMaps      2

#define kABDecimalGroupTag (-1)
#define kABOtherGroupTag   (-2)

//#define kABCallPhoneNumberNotification @"ABCallPhoneNumber"

@interface ABMenuController : NSObject
{
    ABAddressBook* addressBook;
    NSStatusItem* statusItem;
    
    // Open controllers
    NSMutableArray* openControllers;
    
    // Recent menu stuff
    NSMenu* recentMenu;
    NSMenuItem* recentSubMenu;
    NSMutableArray* recentContacts;
    
    // Bonjour contacts stuff
    ABMenuBonjourController* bonjourController;
    IBOutlet NSMenu* theMenu;
    IBOutlet NSMenu* cmdMenu;
    IBOutlet NSPanel* prefsPanel;
    
    // Search panel stuff
    IBOutlet NSPanel* searchPanel;
    IBOutlet ABPeoplePickerView* peopleView;
    
    // Preferences-related controls
    IBOutlet NSSlider* opacitySlider;
    IBOutlet NSMatrix* windowModeMatrix;
    IBOutlet NSButton* showAllRecordsButton;
    IBOutlet NSButton* alphaGroupButton;
    IBOutlet NSButton* showGroupRecordsButton;
    IBOutlet NSButton* showUngroupedContactsButton;
    IBOutlet NSTextField* recentContactsField;
    IBOutlet NSButton* publishBonjourButton;
    IBOutlet NSButton* showBonjourContactsButton;
    IBOutlet NSPopUpButton* mapAddressSiteButton;
    IBOutlet NSButton* autoLaunchButton;
    IBOutlet NSMatrix* sortModeMatrix;
    IBOutlet NSButton* autoOpenNotesButton;
    IBOutlet NSButton* autoCloseAfterActionButton;
}

//
// Private
-(void)setupBonjour;
-(void)shutdownBonjour;
-(void)registerForNotifications;
-(void)unregisterForNotifications;
-(NSStatusItem*)createStatusItem:(NSMenu*)menu;
-(void)createRecentMenu;
-(void)reloadRecentContacts;
-(void)populateMainMenu;
-(void)addRecentContact:(ABPerson*)contact;
-(void)addGroup:(ABGroup*)group toMenu:(NSMenu*)menu;
-(void)addUngroupedContactsToMenu:(NSMenu*)menu;
-(NSMenuItem *)menuItemForRecord:(ABRecord*)record withSelector:(SEL)selector;
-(void)openCardForContact:(ABPerson*)contact;

-(IBAction)toggleShowUngrouped:(id)sender;

@end
