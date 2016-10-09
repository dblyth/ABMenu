//
//  ABMenuCardController.m
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import "ABMenuCardController.h"
#import "ABMenuController.h"
#import "ABRecordAdditions.h"
#import "ABMenuTextCell.h"

#import "AddressBook/ABAddressBook.h"
#import "AddressBook/ABImageLoading.h"

@implementation ABMenuCardController

static bool imagesLoaded = NO;
static NSImage *urlImage;
static NSImage *addressImage;
static NSImage *phoneImage;
static NSImage *emailImage;
static NSImage *chatImage;

#pragma mark -
#pragma mark *** NSObject ***

-(id)initWithContact:(ABPerson *)contact
{
    if (self = [super initWithWindowNibName:@"Card"])
    {
        representedPerson = [contact retain]; // Added this line after running scan-build
        
        propertyArray = [[NSMutableArray alloc] initWithCapacity:0];
        
        // Check to see if images have been loaded already
        if (imagesLoaded == NO)
        {
            urlImage = [[NSImage imageNamed:@"arrow"] retain];
            addressImage = [[NSImage imageNamed:@"globe2"] retain];
            phoneImage = [[NSImage imageNamed:@"phone3"] retain];
            emailImage = [[NSImage imageNamed:@"email"] retain];
            chatImage = [[NSImage imageNamed:@"chat"] retain];
            
            imagesLoaded = YES;
        }
        
    }
    
    return self;
}

-(void)dealloc
{
    [representedPerson release];
    [propertyArray release];
    
    [super dealloc];
}

-(void)awakeFromNib
{    
    // Select the panel based on the preference
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABUseHUDCardInterface])
    {
        [self setWindow:hudPanel];
        [infoList setHudStyle:YES];
        [noteView setHudStyle:YES];
    }
    else
    {
        [self setWindow:normalPanel];
        [infoList setHudStyle:NO];
        [noteView setHudStyle:NO];
    }
    
    // Load the actual content view into the panel
    [[self window] setContentView:infoView];
    
    // Modify the cell of the table view
    [[[infoList tableColumns] objectAtIndex:[infoList columnWithIdentifier:kValueDictKey]] setDataCell:[[[ABMenuTextCell alloc] initTextCell:@""] autorelease]];
    [[[infoList tableColumns] objectAtIndex:[infoList columnWithIdentifier:kLabelDictKey]] setDataCell:[[[ABMenuTextCell alloc] initTextCell:@""] autorelease]];
	
    // Set up the information view
    [infoList setDoubleAction:@selector(doubleClick:)];
	[[self window] setInitialFirstResponder:infoList];
    [actionButton setAutoenablesItems:NO];
    
    // Make sure the window stays visible
    [[self window] setHidesOnDeactivate:NO];
    [[self window] setLevel:NSStatusWindowLevel];
    
    // Build the card
    [self buildCard];
    [self validateActionMenu];
}

-(void)windowDidLoad
{
    if (([[NSUserDefaults standardUserDefaults] boolForKey:kABAutoOpenNotes]) &&
        (nil != [representedPerson valueForProperty:kABNoteProperty]))
    {
        [self performSelector:@selector(autoOpenNotes) withObject:nil afterDelay:0.5];
    }
}

#pragma mark -
#pragma mark *** IBActions ***

-(void)doubleClick:(id)sender
{
    NSInteger row = [infoList selectedRow];
    BOOL rowSelected = (row != -1);
    
    if (rowSelected)
    {
        if ([[[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey] isEqualToString:kABEmailProperty])
            [self sendEmail:sender];
        else if ([[[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey] isEqualToString:kABURLsProperty])
            [self goToLocation:sender];
        else if ([[[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey] isEqualToString:kABAddressProperty])
            [self mapAddress:sender];
        else if ([self isIMProperty:[[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey]])
            [self instantMessage:sender];
    }
}

-(IBAction)editContact:(id)sender
{
	NSString *url = [NSString stringWithFormat:@"addressbook://%@?edit", [representedPerson uniqueId]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];	
}

-(IBAction)sendEmail:(id)sender
{
    NSInteger row = [infoList selectedRow];
    BOOL rowSelected = (row != -1);
    
    // If an email row is selected, go to a mailto:// url
    if (rowSelected && [[[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey] isEqualToString:kABEmailProperty])
    {
        NSString *url = [NSString stringWithFormat:@"mailto:%@", [[propertyArray objectAtIndex:row] valueForKey:kValueDictKey]];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
    
    [self closeCardIfNecessary];
}

-(IBAction)goToLocation:(id)sender
{
    NSInteger row = [infoList selectedRow];
    BOOL rowSelected = (row != -1);
    
    // If a URL property is selected, go to the url
    if (rowSelected && [[[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey] isEqualToString:kABURLsProperty])
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[propertyArray objectAtIndex:row] valueForKey:kValueDictKey]]];
    }
    
    [self closeCardIfNecessary];
}

-(IBAction)mapAddress:(id)sender
{
    NSInteger row = [infoList selectedRow];
    BOOL rowSelected = (row != -1);
    
    // If an address row is selected, use a mapping service
    if (rowSelected && [[[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey] isEqualToString:kABAddressProperty])
    {
        NSMutableString *url = nil;
        
        switch ([[NSUserDefaults standardUserDefaults] integerForKey:kABMapAddressSite])
        {
            case kGoogleMaps:
                url = [NSMutableString stringWithFormat:@"http://maps.google.com/maps?q=%@", [[propertyArray objectAtIndex:row] valueForKey:kValueDictKey]];
                break;
                
            case kLiveMaps:
                url = [NSMutableString stringWithFormat:@"http://www.bing.com/maps/?q=%@", [[propertyArray objectAtIndex:row] valueForKey:kValueDictKey]];
                break;
                
            case kYahooMaps:
                url = [NSMutableString stringWithFormat:@"http://maps.yahoo.com/index.php?q1=%@", [[propertyArray objectAtIndex:row] valueForKey:kValueDictKey]];
                break;
        }
        
        if (url)
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    
        }
    }
    
    [self closeCardIfNecessary];
}

-(IBAction)instantMessage:(id)sender
{    
    NSInteger row = [infoList selectedRow];
    BOOL rowSelected = (row != -1);
    
    NSString *type = [[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey];
    NSString *value = [[[propertyArray objectAtIndex:row] valueForKey:kValueDictKey] valueForKey:kABInstantMessageServiceKey];
    
    // If an address row is selected, use a mapping service
    if (rowSelected && [self isIMProperty:type])
    {
        NSString* url = nil;
        
        // Depends on type
        if ([type isEqualToString:kABInstantMessageServiceAIM])
        {
            url = [NSString stringWithFormat:@"aim:goim?screenname=%@", value];
        }
        else if ([type isEqualToString:kABInstantMessageServiceJabber])
        {
            url = [NSString stringWithFormat:@"xmpp:user%@?message", value];
        }
        else if ([type isEqualToString:kABInstantMessageServiceMSN])
        {
            url = [NSString stringWithFormat:@"msn:chat?contact=%@", value];
        }
        else if ([type isEqualToString:kABInstantMessageServiceYahoo])
        {
            url = [NSString stringWithFormat:@"ymsgr:sendim?%@", value];
        }
        
        if (url)
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
        }
    }
    
    [self closeCardIfNecessary];
}

-(IBAction)copy:(id)sender
{
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSInteger row = [infoList selectedRow];
	
	NSDictionary *selection = [propertyArray objectAtIndex:row];
	
    // Put the value string on the clipboard
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    [pb setString:[selection objectForKey:kValueDictKey] forType:NSStringPboardType];
}

- (IBAction)noteDisclosureClick:(id)sender
{
    // firstView, secondView are outlets
    NSViewAnimation *theAnim;
    NSRect firstWindowFrame;
    NSRect newWindowFrame;
    NSMutableDictionary* animDict;
    
    int offset = ([sender state] ? 1 : -1);
    
    {
        // Create the attributes dictionary for the first view.
        animDict = [NSMutableDictionary dictionaryWithCapacity:3];
        firstWindowFrame = [[self window] frame];
        
        // Specify which view to modify.
        [animDict setObject:[self window] forKey:NSViewAnimationTargetKey];
        
        // Specify the starting position of the view.
        [animDict setObject:[NSValue valueWithRect:firstWindowFrame] forKey:NSViewAnimationStartFrameKey];
        
        // Change the ending position of the view.
        newWindowFrame = firstWindowFrame;
        newWindowFrame.size.height += (offset * 100);
        newWindowFrame.origin.y -= (offset * 100);
        [animDict setObject:[NSValue valueWithRect:newWindowFrame] forKey:NSViewAnimationEndFrameKey];
    }
    
    // Create the view animation object and set some properties
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animDict, nil]];
    [theAnim setDuration:0.5];
    [theAnim setAnimationCurve:NSAnimationEaseInOut];
    
    // Run the animation.
    [theAnim startAnimation];
    [theAnim release];
}

#pragma mark -
#pragma mark *** ABMenuCardController ***

-(void)buildCard
{
    // Clear out the properties in case the card is being rebuilt
    [self clearProperties];
    
    // Modify the font color based on the display preference
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABUseHUDCardInterface] == YES)
    {
        [nameField setTextColor:[NSColor whiteColor]];
        [titleField setTextColor:[NSColor whiteColor]];
    }
    else
    {        
        [nameField setTextColor:[NSColor blackColor]];
        [titleField setTextColor:[NSColor blackColor]];
    }
    
    // Set the icon view
    NSImage *icon = [[NSImage alloc] initWithData:[representedPerson imageData]];
	[iconView setImage:icon];
    [icon release]; // Added this line after running scan-build
    
    // Set the name field
    [nameField setStringValue:[representedPerson displayName]];
    
    // Handle specifics whether its a company or person
    if ([representedPerson showAsPerson])
    {
        if (![iconView image])
            [iconView setImage:[NSImage imageNamed:@"GenericPerson.tiff"]];
        
         // Set organization/job title field
        if ([representedPerson valueForProperty:kABOrganizationProperty])
            [titleField setStringValue:[representedPerson valueForProperty:kABOrganizationProperty]];
        else
            [titleField setStringValue:@""];
    }
    else if ([representedPerson showAsCompany])
    {
        if (![iconView image])
            [iconView setImage:[NSImage imageNamed:@"GenericCompany"]];
        
        // Set organization/job title field
        [titleField setStringValue:@""];
    }
    
    // Set the opacity
    [self setCardAlpha:[[NSUserDefaults standardUserDefaults] floatForKey:kABWindowOpacity]];
    
    // Add the actual information
    [self addPropertiesToTable];
    [infoList reloadData];
}

-(void)setCardAlpha:(float)newAlpha
{
	if (newAlpha >= 1.0)
	{
		[[self window] setOpaque:YES];
		[[self window] setAlphaValue:1.0];
	}
	else
	{
		[[self window] setOpaque:NO];
		[[self window] setAlphaValue:newAlpha];
	}
}

-(void)validateActionMenu
{
    NSInteger row = [infoList selectedRow];
    BOOL rowSelected = (row != -1);
    
    NSString* typeValue;
    if (rowSelected)
    {
        typeValue = [[propertyArray objectAtIndex:row] valueForKey:kTypeDictKey];
    }
    
    // 'Edit Card' always enabled
    [[actionMenu itemAtIndex:kABEditCardMenuItem] setEnabled:YES];
    
    // 'Copy' is enabled if any row is selected
    [[actionMenu itemAtIndex:kABCopyMenuItem] setEnabled:rowSelected];
    
    // The rest are enabled depending on the type of the selection
    [[actionMenu itemAtIndex:kABSendEmailMenuItem] setEnabled:(rowSelected && [typeValue isEqualToString:kABEmailProperty])];
    [[actionMenu itemAtIndex:kABGoToLocationMenuItem] setEnabled:(rowSelected && [typeValue isEqualToString:kABURLsProperty])];
    [[actionMenu itemAtIndex:kABMapAddressMenuItem] setEnabled:(rowSelected && [typeValue isEqualToString:kABAddressProperty])];
    
    // Since there is no way to some types of messengers, disable the instant message item depending on the type
    if (rowSelected && [self isIMProperty:typeValue])
    {
        NSString* imType = [[[propertyArray objectAtIndex:row] valueForKey:kValueDictKey] valueForKey:kABInstantMessageServiceKey];
        [[actionMenu itemAtIndex:kABSendInstantMessageMenuItem] setEnabled:[self isInstantMessageTypeActionSupported:imType]];
    }
    else
    {
        [[actionMenu itemAtIndex:kABSendInstantMessageMenuItem] setEnabled:NO];
    }
}

-(void)clearProperties
{
    [propertyArray removeAllObjects];
}

-(BOOL)isIMProperty:(NSString *)type {
    
    return [type isEqualToString:kABInstantMessageProperty];
}

-(BOOL)isInstantMessageTypeActionSupported:(NSString *)imType
{
    return [imType isEqualToString:kABInstantMessageServiceAIM] ||
           [imType isEqualToString:kABInstantMessageServiceJabber] ||
           [imType isEqualToString:kABInstantMessageServiceMSN] ||
           [imType isEqualToString:kABInstantMessageServiceYahoo];
}

-(void)addPropertiesToTable
{
    int i;
    
    // Phone Numbers
    [self addMultiValueProperty:kABPhoneProperty];
    
    // Email Addresses
    [self addMultiValueProperty:kABEmailProperty];
    
    // URLs
    [self addMultiValueProperty:kABURLsProperty];
    
    // Addresses -- must do separately to build the address string
    ABMultiValue *addresses = [representedPerson valueForProperty:kABAddressProperty];
    for (i = 0; i < [addresses count]; i++)
    {
        [propertyArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[self scanLabel:[addresses labelAtIndex:i]], kLabelDictKey,
                                  [self buildAddress:[addresses valueAtIndex:i]], kValueDictKey,
                                  kABAddressProperty, kTypeDictKey,
                                  nil]];
    }
    
    // Instant messaging
    [self addMultiValueProperty:kABInstantMessageProperty];
    
    // Notes
    NSString* noteString = [representedPerson valueForProperty:kABNoteProperty];
    if (noteString == nil)
    {
        noteString = @"";
    }
    
    [noteView setString:noteString];
}

-(void)addMultiValueProperty:(NSString *)property
{
    ABMultiValue *multiValue;
    
    if ((multiValue = [representedPerson valueForProperty:property]))
    {
        int i;
        
        for (i = 0; i < [multiValue count]; i++)
        {
            [propertyArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[self scanLabel:[multiValue labelAtIndex:i]], kLabelDictKey,
                                      [multiValue valueAtIndex:i], kValueDictKey,
                                      property, kTypeDictKey,
                                      nil]];
        }
    }
}

-(NSString *)scanLabel:(NSString *)label
{
    if ([label hasPrefix:@"_$!<"])
    {
        NSScanner *scanner = [NSScanner scannerWithString:label];
        NSString *labelString;
        
        [scanner scanString:@"_$!<" intoString:nil];
        [scanner scanUpToString:@">!$_" intoString:&labelString];
        
        return labelString;
    }
    else
        return [label capitalizedString];
}

-(NSString *)scanIMType:(NSString *)type
{
    NSScanner *scanner = [NSScanner scannerWithString:type];
    NSString *shortType = nil;
    
    [scanner scanUpToString:@"Instant" intoString:&shortType];
    
    if (shortType)
        return shortType;
    else
        return type;
}

-(NSString *)buildAddress:(NSDictionary *)addressDict
{
    NSMutableString* addressString = [NSMutableString stringWithString:[[[ABAddressBook sharedAddressBook] formattedAddressFromDictionary:addressDict] string]];
    
    // Remove any new lines
    [addressString replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, [addressString length])];
    
    return addressString;
}

-(ABPerson *)representedPerson
{
    return representedPerson;
}

-(void)autoOpenNotes
{
    [disclosureButton setState:NSOnState];
    [self noteDisclosureClick:disclosureButton];
}

-(void)closeCardIfNecessary
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABAutoCloseAfterAction] == YES)
    {
        [self close];
    }
}

#pragma mark -
#pragma mark *** ABMenuPanel Delegate ***

-(void)keyDown:(NSEvent *)theEvent
{
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    
	switch (key)
	{
		case 0x0D: // return
		case 0x03: // enter
			[self doubleClick:nil];
			break;
	}
}


#pragma mark -
#pragma mark *** NSWindow Delegate ***

- (BOOL)windowShouldClose:(id)sender
{
    // Post a notification so that the ABMenuController can remove this controller from the list
    // of open controllers
    [[NSNotificationCenter defaultCenter] postNotificationName:kABControllerClosedNotification object:self];
    
    return YES;
}

#pragma mark -
#pragma mark *** NSTableView Delegate ***

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [propertyArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
    NSDictionary *infoDict = [propertyArray objectAtIndex:rowIndex];
    
    // Represent the property type by an image instead of text
    if ([[column identifier] isEqualToString:kTypeDictKey])
    {
        if ([[[propertyArray objectAtIndex:rowIndex] valueForKey:kTypeDictKey] isEqualToString:kABURLsProperty])
            return urlImage;
        else if ([[[propertyArray objectAtIndex:rowIndex] valueForKey:kTypeDictKey] isEqualToString:kABAddressProperty])
            return addressImage;
        else if ([[[propertyArray objectAtIndex:rowIndex] valueForKey:kTypeDictKey] isEqualToString:kABPhoneProperty])
            return phoneImage;
        else if ([[[propertyArray objectAtIndex:rowIndex] valueForKey:kTypeDictKey] isEqualToString:kABEmailProperty])
            return emailImage;
        else if ([[[propertyArray objectAtIndex:rowIndex] valueForKey:kTypeDictKey] isEqualToString:
            kABInstantMessageProperty])
            return chatImage;
        else
            return nil;
    }
    else if (([[column identifier] isEqualToString:kValueDictKey]) && ([self isIMProperty:[[propertyArray objectAtIndex:rowIndex] valueForKey:kTypeDictKey]]))
    {
        NSDictionary* imDict = (NSDictionary*)[[propertyArray objectAtIndex:rowIndex] valueForKey:kValueDictKey];
        
        // Append the IM type after the IM handle
        return [NSString stringWithFormat:@"%@ (%@)", [imDict valueForKey:kABInstantMessageUsernameKey], [self scanIMType:[imDict valueForKey:kABInstantMessageServiceKey]]];
    }
    else
        return [infoDict objectForKey:[column identifier]];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(int)rowIndex 
{
    // Make the font size a little larger to increase legibility
    if ([[column identifier] isEqualToString:kValueDictKey])
    {
        [cell setFont:[NSFont titleBarFontOfSize:18.0]];
    }
    
    if (![[column identifier] isEqualToString:kTypeDictKey])
    {
        [(ABMenuInfoTableView*)aTableView styleCell:cell];
    }
}

-(NSMenu *)tableView:(NSTableView *)aTableView menuForTableColumn:(NSTableColumn *)column row:(NSInteger)rowIndex
{
    // Update the action menu in case we hit this method before tableViewSelectionDidChange
	[self validateActionMenu];
	
    return actionMenu;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self validateActionMenu];
}


@end
