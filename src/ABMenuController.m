//
//  ABMenuController.m
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import "ABMenuController.h"
#import "ABMenuCardController.h"
#import "ABRecordAdditions.h"
////#import "UKLoginItemRegistry.h"

@implementation ABMenuController

#pragma mark -
#pragma mark *** NSObject ***

+(void)initialize
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    //
    // Regular interface, 80% opacity
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:kABUseHUDCardInterface];
    [defaultValues setObject:[NSNumber numberWithFloat:0.8] forKey:kABWindowOpacity];
    
    // 
    // Show groups, show all records grouped into alphabetical submenus, sorting by last name
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:kABShowGroupSubmenus];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:kABShowAllRecords];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:kABSortIntoAlphabeticalSubMenus];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:kABSortByLastName];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:kABAutoOpenNotes];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:kABAutoCloseAfterAction];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:kABShowUngroupedContacts];
    
    //
    // Bonjour off
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:kABShowBonjourContacts];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:kABPublishBonjourInfo];
    
    //
    // Empty list of recent contacts, max 10
    [defaultValues setObject:[NSNumber numberWithInt:10] forKey:kABNumRecentContacts];
    [defaultValues setObject:[NSArray array] forKey:kABRecentContactsArray];
    
    //
    // Default to Google Maps
    [defaultValues setObject:[NSNumber numberWithInt:kGoogleMaps] forKey:kABMapAddressSite];
    
    //
    // Set the defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

-(id)init
{
    if (self = [super init])
    {
        //
        // Setup notifications so that this object can be notified
        // when things happen.
        [self registerForNotifications];
    
        //
        // Store a reference to the address book database
        addressBook = [ABAddressBook sharedAddressBook];
        
        // 
        // Need to maintain pointers to all open card controllers
        // so we can update/close them appropriately.
        openControllers = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    return self;
}

-(void)dealloc
{
    [openControllers release];
    [self unregisterForNotifications];
        
    [super dealloc];
}

- (void)awakeFromNib
{
    // 
    // Create the status item
    statusItem = [self createStatusItem:theMenu];
    
    //
    // Setup recent contact menu
    [self createRecentMenu];
    
    //
    // Setup Bonjour
    [self setupBonjour];
    
    // Setup the search panel
    [peopleView setTarget:self];
    [peopleView setNameDoubleAction:@selector(pickerDoubleClick:)];
    
    // Go ahead and build the menu
    [self populateMainMenu];
    
    // Ready to go
    [[NSApplication sharedApplication] setDelegate:self];
}

#pragma mark -
#pragma mark *** ABMenuController ***

#pragma mark - Bonjour
-(void)setupBonjour
{
    //
    // Setup the controller that handles all the Bonjour-related events
    bonjourController = [[ABMenuBonjourController alloc] init];
    
    //
    // Enable if the preferences say so
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABPublishBonjourInfo])
    {
        [bonjourController startBroadcasting];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABShowBonjourContacts])
    {
        [bonjourController startListening];
    }
}

-(void)shutdownBonjour
{
    [bonjourController stopListening];
    [bonjourController stopBroadcasting];
}

#pragma mark - Notifications
-(void)registerForNotifications
{
    // Get the default notificaiton center
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    // Register for changes by the AddressBook.app
    [nc addObserver:self 
           selector:@selector(handleChangedDatabase:)
               name:kABDatabaseChangedNotification
             object:nil];
    
    // Register for changes to the address book database by other apps
    [nc addObserver:self 
           selector:@selector(handleChangedDatabase:) 
               name:kABDatabaseChangedExternallyNotification
             object:nil];
    
    // Register for Bonjour updates
    [nc addObserver:self
           selector:@selector(handleBonjourUpdate:)
               name:kABBonjourUpdateNotification
             object:nil];
    
    // Register to view Bonjour contacts
    [nc addObserver:self
           selector:@selector(viewBonjourCard:)
               name:kABBonjourViewCardNotification
             object:nil];
    
    // Register to handle closed cards
    [nc addObserver:self
           selector:@selector(cardClosed:)
               name:kABControllerClosedNotification
             object:nil];
}

-(void)unregisterForNotifications
{
    //
    // Remove notifications
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:kABDatabaseChangedNotification object:nil];
    [nc removeObserver:self name:kABDatabaseChangedExternallyNotification object:nil];
    [nc removeObserver:self name:kABBonjourUpdateNotification object:nil];
    [nc removeObserver:self name:kABBonjourViewCardNotification object:nil];
    [nc removeObserver:self name:kABControllerClosedNotification object:nil];
}

#pragma mark - Recent Contacts Menu
-(void)createRecentMenu
{
    recentMenu = [[NSMenu alloc] initWithTitle:@"recent"];
    [recentMenu setAutoenablesItems:NO];
    
    //
    // Load the recent contacts from the preferences plist
    [self reloadRecentContacts];

    //
    // Create the submenu item that will be placed in the main menu
    recentSubMenu = [[NSMenuItem alloc] initWithTitle:@"Recent Contacts" action:nil keyEquivalent:@""];
    [recentSubMenu setTarget:self];
    [recentSubMenu setSubmenu:recentMenu];
    [recentSubMenu setEnabled:NO];
    [self addRecentContact:nil];
}

-(void)reloadRecentContacts
{
    if (recentContacts != NULL)
    {
        [recentContacts release];
    }
    
    recentContacts = [[NSMutableArray alloc] initWithCapacity:[[[NSUserDefaults standardUserDefaults] arrayForKey:kABRecentContactsArray] count]];    
    NSEnumerator *enumerator = [[[NSUserDefaults standardUserDefaults] arrayForKey:kABRecentContactsArray] objectEnumerator];
    NSString *contactId;
    
    while ((contactId = [enumerator nextObject]))
    {
        ABRecord *contact = [addressBook recordForUniqueId:contactId];
        
        // NULL means the contact was found over the network or it no longer exists
        // Either way, ignore it.
        if (contact != NULL) 
            [recentContacts addObject:contact];
    }
}

-(void)saveRecentContacts
{
    NSMutableArray *recentIdArray = [NSMutableArray arrayWithCapacity:[recentContacts count]];
    NSEnumerator *enumerator = [recentContacts objectEnumerator];
    ABPerson *contact;
    while ((contact = [enumerator nextObject]))
    {
        [recentIdArray addObject:[contact uniqueId]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:recentIdArray] forKey:kABRecentContactsArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)addRecentContact:(ABPerson *)contact
{
    int maxRecentContacts = [[NSUserDefaults standardUserDefaults] integerForKey:kABNumRecentContacts];
    
    //
    // If the user doesn't want to store recent contacts, we are done here.
    if (maxRecentContacts <= 0)
    {
        return;
    }
    
    //
    // The user does want to store them, so we have work to do.
    int i;
    NSEnumerator *enumerator = [[recentMenu itemArray] objectEnumerator]; 
    NSMenuItem *item;
        
    //
    // Remove all menu items from the recent contacts menu
    while ((item = [enumerator nextObject]))
    {
        [recentMenu removeItem:item];
    }
        
    // 
    // Remove the object if it is already there, then add to the front of the list
    if (contact != NULL)
    {
        if ([recentContacts containsObject:contact])
            [recentContacts removeObject:contact];
        
        [recentContacts insertObject:contact atIndex:0];
    }
    
    //
    // If the list is now too large, items from the back
    for (i = maxRecentContacts; i < [recentContacts count]; i++)
    {
        [recentContacts removeObjectAtIndex:i];
    }
    
    // 
    // Add the recent contacts list back into the menu
    for (i = [recentContacts count]-1; i >= 0; i--) 
    {
        ABPerson* contact = [recentContacts objectAtIndex:i];
        
        // Alloc a new item
        item = [[NSMenuItem alloc] initWithTitle:[contact displayName] action:@selector(viewCard:) keyEquivalent:@""];
        [item setTarget:self];
        
        // Store the contact id as the represented object so it can be read when the item is selected
        [item setRepresentedObject:[recentContacts objectAtIndex:i]];
        
        [item setImage:[contact smallImage]];
        
        // 
        [recentMenu insertItem:item atIndex:0];
        
        [item release]; 
    }
       
    // 
    // Add the extras at the bottom of the menu
    [recentMenu addItem:[NSMenuItem separatorItem]];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Clear Recent Contacts" action:@selector(clearRecent:) keyEquivalent:@""];
    [item setTarget:self];
    [recentMenu addItem:item];
    [item release];
        
    //
    // Enable/disable the menu depending on if there are recent contacts
    [recentSubMenu setEnabled:([recentContacts count] > 0)];
}

#pragma mark - Main menu building
-(void)populateMainMenu
{    
    NSEnumerator *enumerator = [[theMenu itemArray] objectEnumerator];
	NSMenuItem *item;
    
    //
	// Remove all items from menu
	while ((item = [enumerator nextObject]))
	{
        [theMenu removeItem:item];
	}
    
    //
    // Add the ABMenu sub menu for misc. commands
    item = [[NSMenuItem alloc] initWithTitle:@"ABMenu" action:nil keyEquivalent:@""];
    [item setSubmenu:cmdMenu];
    [theMenu addItem:item];
    [item release];
    
    //
    // Add the submenu for recent contacts (if preference is activated)
    if ([[NSUserDefaults standardUserDefaults] integerForKey:kABNumRecentContacts] > 0)
    {
        [theMenu addItem:[NSMenuItem separatorItem]];
        [theMenu addItem:recentSubMenu];
    }
    
    // 
    // Bonjour contacts here (if preference is activated)
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABShowBonjourContacts])
    {
        // Separate from the previous items
        [theMenu addItem:[NSMenuItem separatorItem]];
        
        item = [[NSMenuItem alloc] initWithTitle:@"Bonjour Contacts" action:nil keyEquivalent:@""];
        NSMenu *bonjourMenu = [bonjourController serviceMenu];
        [item setSubmenu:bonjourMenu];
        [theMenu addItem:item];
        [item release];
        
        if ([bonjourMenu numberOfItems] == 0)
            [item setEnabled:NO];
    }
    
    //
    // AB group submenus here if preference is activated
    if (([[NSUserDefaults standardUserDefaults] boolForKey:kABShowGroupSubmenus] == YES) &&
        ([[addressBook groups] count] > 0))
    {
        // Separate from the previous items
        [theMenu addItem:[NSMenuItem separatorItem]];
        
        // Iterate over each group
        NSEnumerator *groupEnumerator = [[[NSMutableArray arrayWithArray:[addressBook groups]] sortedArrayUsingSelector:@selector(displayNameComparison:)] objectEnumerator];
        ABGroup *group;
        
        while ((group = [groupEnumerator nextObject]))
        {
            [self addGroup:group toMenu:theMenu];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kABShowUngroupedContacts] == YES)
        {
            [self addUngroupedContactsToMenu:theMenu];
        }
    }
    
    //
    // Show all users
    if (([[NSUserDefaults standardUserDefaults] boolForKey:kABShowAllRecords] == YES) &&
        ([[addressBook people] count] > 0))
    {
        NSEnumerator *personEnumerator = [[[NSMutableArray arrayWithArray:[addressBook people]] sortedArrayUsingSelector:@selector(sortOrderComparison:)] objectEnumerator];
        ABPerson *person;
        
        // Separate from the previous items
        [theMenu addItem:[NSMenuItem separatorItem]];
        
        // Enumerate the people sorted by display name
        while ((person = [personEnumerator nextObject]))
        {          
            BOOL addedParentMenu = NO;
            NSMenuItem *parentMenuItem;
            
            // Get a menu item for this person
            item = [self menuItemForRecord:person withSelector:@selector(viewCard:)];
            
            // Either sort into alphabetical menus or just list them
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kABSortIntoAlphabeticalSubMenus])
            {
                // Get the first character
                int indexChar = toupper([[[person sortName] decomposedStringWithCanonicalMapping] characterAtIndex:0]);
                
                // Check if the person belongs in the "0-9" menu item
                if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:indexChar])
                {
                    parentMenuItem = [theMenu itemWithTag:kABDecimalGroupTag];
                    if (parentMenuItem == nil)
                    {
                        parentMenuItem = [[NSMenuItem alloc] initWithTitle:@"0-9" action:nil keyEquivalent:@""];
                        [parentMenuItem setTag:kABDecimalGroupTag];
                        
                        [theMenu addItem:parentMenuItem];
                        
                        addedParentMenu = YES;
                    }
                }
                else if ([[[NSCharacterSet uppercaseLetterCharacterSet] invertedSet] characterIsMember:indexChar])
                {
                    // The person belongs in the "Other" menu item
                    parentMenuItem = [theMenu itemWithTag:kABOtherGroupTag];
                    if (parentMenuItem == nil)
                    {
                        parentMenuItem = [[NSMenuItem alloc] initWithTitle:@"Other" action:nil keyEquivalent:@""];
                        [parentMenuItem setTag:kABOtherGroupTag];
                        
                        [theMenu addItem:parentMenuItem];
                        
                        addedParentMenu = YES;
                    }
                }
                else
                {
                    // Find the alphabetical menu if it has already been created, otherwise create one
                    parentMenuItem = [theMenu itemWithTag:indexChar];
                    if (parentMenuItem == nil)
                    {
                        NSString *menuTitle = [NSString stringWithFormat:@"%C", indexChar];
                        parentMenuItem = [[NSMenuItem alloc] initWithTitle:menuTitle action:nil keyEquivalent:@""];
                        [parentMenuItem setTag:indexChar];
                        [theMenu addItem:parentMenuItem];
                        
                        addedParentMenu = YES;
                    }
                }
                
                // Add a submenu to the parent menu if necessary
                if ([parentMenuItem submenu] == nil)
                {
                    NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"submenu"];
                    [parentMenuItem setSubmenu:submenu];
                    [submenu release];
                }
                
                // Add the newly created menu item to the designated parent item
                [[parentMenuItem submenu] addItem:item];
            }
            else 
            {
                // Not grouping, so just add to the end of the menu as we are already sorted
                [theMenu addItem:item];
            }
            
            [item release];
            
            // If we added a submenu, release it
            if (addedParentMenu)
            {
                [parentMenuItem release];
            }
        }
    }
}

#pragma mark - Miscellaneous

-(void)addUngroupedContactsToMenu:(NSMenu*)menu
{
    NSMenuItem *item;
    NSMenuItem *submenuItem = nil;
    NSMenu *submenu = nil;
    NSEnumerator *enumerator;
    ABPerson *person;
    
    enumerator = [[[NSMutableArray arrayWithArray:[addressBook people]] sortedArrayUsingSelector:@selector(sortOrderComparison:)] objectEnumerator];
    while ((person = [enumerator nextObject]))
    {
        if (([person parentGroups] == nil) ||
            ([[person parentGroups] count] == 0))
        {
            if (submenuItem == nil)
            {
                submenuItem = [[NSMenuItem alloc] initWithTitle:@"Ungrouped" action:nil keyEquivalent:@""];
                [submenuItem setTarget:self];    
                [submenuItem setImage:[NSImage imageNamed:@"smartgroup"]];
                [menu addItem:submenuItem];
                
                submenu = [[NSMenu alloc] initWithTitle:@"submenu"];
                [submenuItem setSubmenu:submenu];
            }
            
            item = [self menuItemForRecord:person withSelector:@selector(viewCard:)];
            [submenu addItem:item];
            [item release];
        }
    }
    
    if (submenuItem != nil)
    {
        [submenu release];
        [submenuItem release];
    }
}

-(void)addGroup:(ABGroup *)group toMenu:(NSMenu *)menu
{
    NSMenuItem *item;
    NSEnumerator *enumerator;
    ABRecord *record;
    
    //
    // Add an item for the group
    item = [[NSMenuItem alloc] initWithTitle:[group valueForProperty:kABGroupNameProperty] action:nil keyEquivalent:@""];
    [item setTarget:self];    
    [item setImage:[group smallImage]];
    [menu addItem:item];
    
    //
    // Recursively add subgroups as a submenu
    NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"submenu"];
    [item setSubmenu:submenu];
    
    if ([[group subgroups] count] > 0)
    {
        enumerator = [[[NSMutableArray arrayWithArray:[group subgroups]] sortedArrayUsingSelector:@selector(displayNameComparison:)] objectEnumerator];
        
        while ((record = [enumerator nextObject]))
        {
            [self addGroup:(ABGroup*)record toMenu:submenu];
        }
        
        [submenu addItem:[NSMenuItem separatorItem]];
    }
    
    //
    // Now do the contact members
    enumerator = [[[NSMutableArray arrayWithArray:[group members]] sortedArrayUsingSelector:@selector(sortOrderComparison:)] objectEnumerator];
    
    while ((record = [enumerator nextObject]))
    {
        NSMenuItem *groupItem = [self menuItemForRecord:record withSelector:@selector(viewCard:)];
        
        [submenu addItem:groupItem];
        
        [groupItem release];
    }
    
    [submenu release];
    [item release];
}

-(NSMenuItem *)menuItemForRecord:(ABRecord *)record withSelector:(SEL)selector
{
    NSMenuItem *contactItem = [[NSMenuItem alloc] initWithTitle:[record displayName]
                                                         action:selector
                                                  keyEquivalent:@""];
    
    [contactItem setTarget:self];
    [contactItem setRepresentedObject:record];
    
    //
    // Add an image if necessary
    [contactItem setImage:[record smallImage]];
    
    return contactItem;
}

-(void)openCardForContact:(ABPerson *)contact
{
    //
    // Create a new card controller and add it to the list we maintain
    ABMenuCardController *control = [[[ABMenuCardController alloc] initWithContact:contact] autorelease];
    [openControllers addObject:control];
    
    //
    // Open the card window
    [[control window] makeKeyAndOrderFront:self];
    
    //
    // Update recent menu
    [self addRecentContact:contact];
}

-(NSStatusItem*)createStatusItem:(NSMenu*)menu
{
    NSStatusItem* item = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    
    [item setImage:[NSImage imageNamed:@"newicon"]];
    [item setHighlightMode:YES];
    [item setMenu:menu];
    [item setEnabled:YES];
    
    return item;
}

#pragma mark -
#pragma mark *** IBActions ***

-(IBAction)clearRecent:(id)sender
{
    [recentContacts removeAllObjects];
    
    // Call with nil to rebuild the menu
    [self addRecentContact:nil];
}

-(IBAction)savePreferences:(id)sender
{
    [prefsPanel close];
    
    // Copy new preferences from the controls
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[windowModeMatrix selectedRow]] forKey:kABUseHUDCardInterface];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[opacitySlider floatValue]] forKey:kABWindowOpacity];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[recentContactsField intValue]] forKey:kABNumRecentContacts];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[showAllRecordsButton state]] forKey:kABShowAllRecords];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[showGroupRecordsButton state]] forKey:kABShowGroupSubmenus];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[alphaGroupButton state]] forKey:kABSortIntoAlphabeticalSubMenus];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[showUngroupedContactsButton state]] forKey:kABShowUngroupedContacts];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[showBonjourContactsButton state]] forKey:kABShowBonjourContacts];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[publishBonjourButton state]] forKey:kABPublishBonjourInfo];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[mapAddressSiteButton indexOfSelectedItem]] forKey:kABMapAddressSite];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[sortModeMatrix selectedRow]] forKey:kABSortByLastName];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[autoOpenNotesButton state]] forKey:kABAutoOpenNotes];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)[autoCloseAfterActionButton state]] forKey:kABAutoCloseAfterAction];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Start/stop Bonjour based on new preferences
    ([[NSUserDefaults standardUserDefaults] boolForKey:kABPublishBonjourInfo]) ? [bonjourController startBroadcasting] : [bonjourController stopBroadcasting];
    ([[NSUserDefaults standardUserDefaults] boolForKey:kABShowBonjourContacts]) ? [bonjourController startListening] : [bonjourController stopListening];
    
    // Add or remove login item
    if ((BOOL)[autoLaunchButton state])
    {
        ////[UKLoginItemRegistry addLoginItemWithPath:[[NSBundle mainBundle] bundlePath] hideIt:NO];
    }
    else
    {
        ////[UKLoginItemRegistry removeLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
    }
    
    // Rebuild the main menu
    [self populateMainMenu];
}

-(IBAction)editPreferences:(id)sender
{    
    // Setup the preference controls based on the current preferences
    [opacitySlider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:kABWindowOpacity]];
    [windowModeMatrix selectCellAtRow:(int)[[NSUserDefaults standardUserDefaults] boolForKey:kABUseHUDCardInterface] column:0];
    [showGroupRecordsButton setState:(int)[[NSUserDefaults standardUserDefaults] boolForKey:kABShowGroupSubmenus]];
    [recentContactsField setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:kABNumRecentContacts]];
    [publishBonjourButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:kABPublishBonjourInfo]];
    [showBonjourContactsButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:kABShowBonjourContacts]];
    [mapAddressSiteButton selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kABMapAddressSite]];
    [showAllRecordsButton setState:(int)[[NSUserDefaults standardUserDefaults] boolForKey:kABShowAllRecords]];
    [alphaGroupButton setState:(int)[[NSUserDefaults standardUserDefaults] boolForKey:kABSortIntoAlphabeticalSubMenus]];
    [alphaGroupButton setEnabled:[[NSUserDefaults standardUserDefaults] boolForKey:kABShowAllRecords]];
    [showUngroupedContactsButton setState:(int)[[NSUserDefaults standardUserDefaults] boolForKey:kABShowUngroupedContacts]];
    [showUngroupedContactsButton setEnabled:[[NSUserDefaults standardUserDefaults] boolForKey:kABShowGroupSubmenus]];
    [sortModeMatrix selectCellAtRow:(int)[[NSUserDefaults standardUserDefaults] boolForKey:kABSortByLastName] column:0];
    [autoOpenNotesButton setState:(int)[[NSUserDefaults standardUserDefaults] boolForKey:kABAutoOpenNotes]];
    [autoCloseAfterActionButton setState:(int)[[NSUserDefaults standardUserDefaults] boolForKey:kABAutoCloseAfterAction]];
    
    // Set the launch button based on whether we are a startup item or not.
    ////[autoLaunchButton setState:([UKLoginItemRegistry indexForLoginItemWithPath:[[NSBundle mainBundle] bundlePath]] >= 0)];
    
    // Now show the window
    [prefsPanel makeKeyAndOrderFront:self];
}

-(IBAction)makeNewContact:(id)sender
{    
    NSURL *url = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath]
                                         stringByAppendingPathComponent:@"newcontact.applescript"]];
    
    NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:url error:nil];
	[script executeAndReturnError:nil];
    [script release];
}

-(IBAction)openAddressBook:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"Address Book"];
}

-(IBAction)viewCard:(id)sender
{
    [self openCardForContact:[sender representedObject]];
}

-(IBAction)toggleAlphaSort:(id)sender
{
    [alphaGroupButton setEnabled:[sender state]];
}

-(IBAction)toggleShowUngrouped:(id)sender
{
    [showUngroupedContactsButton setEnabled:[sender state]];
}

-(IBAction)openSearchPanel:(id)sender
{
    [searchPanel makeKeyAndOrderFront:self];
}

-(void)pickerDoubleClick:(id)sender
{
    ABRecord *selectedContact = [[peopleView selectedRecords] objectAtIndex:0];
    
    if ([selectedContact isPerson])
    {
        [self openCardForContact:(ABPerson*)selectedContact];
    }
}

#pragma mark -
#pragma mark *** NSNotification Callbacks ***

-(void)handleBonjourUpdate:(NSNotification *)aNotification
{
    // Call populateMainMenu to update the Bonjour menu
    [self populateMainMenu];
}

-(void)handleChangedDatabase:(NSNotification *)aNotification
{    
    //
    // Update the menus
    [self populateMainMenu]; 
    
    //
    // Iterate the open windows to see if the people they represent were affected by the edit
    NSEnumerator *enumerator = [openControllers objectEnumerator];
    ABMenuCardController *control;
    NSArray *updatedRecords = [[aNotification userInfo] objectForKey:kABUpdatedRecords];
    NSArray *deletedRecords = [[aNotification userInfo] objectForKey:kABDeletedRecords];
    
    while ((control = [enumerator nextObject]))
    {
        // Check this controller to see if the person was updated. If so, rebuild the card
        if (updatedRecords != nil)
        {
            if ([updatedRecords containsObject:[[control representedPerson] uniqueId]])
            {
                [control buildCard];
            }
        }
        
        // If the person was removed, close the window
        if (deletedRecords != nil)
        {
            if ([deletedRecords containsObject:[[control representedPerson] uniqueId]])
            {
                [control close];
            }
        }
    }
}

-(void)viewBonjourCard:(NSNotification *)aNotification
{
    [self openCardForContact:(ABPerson*)[aNotification object]];
}

-(void)cardClosed:(NSNotification *)aNotification
{
    [openControllers removeObject:[aNotification object]];
}

#pragma mark -
#pragma mark *** NSApplication Delegate ***

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
    
    //
    // Save recent contact unique id's to the preferences
    [self saveRecentContacts];
    
    //
    // Shut down the networking
    [self shutdownBonjour];
    
    // 
    // Shut everything down
    [self dealloc];
    
    return NSTerminateNow;
}

@end
