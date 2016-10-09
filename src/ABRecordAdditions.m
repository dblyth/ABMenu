//
//  ABRecordAdditions.m
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import "ABRecordAdditions.h"
#import "ABMenuController.h"

@implementation ABRecord (ABMenuRecordAdditions)

//
// Create a name that can be passed and parsed over the network
-(NSString*)parsableDisplayName
{
    NSString* displayName = @"<No Name>";
    
    if ([self isGroup])
    {
        displayName = [self displayName];
    }
    else if ([self showAsCompany])
    {
        displayName = [self displayName];
    }
    else if ([self showAsPerson])
    {
        NSString *firstName = [self valueForProperty:kABFirstNameProperty];
        NSString *lastName = [self valueForProperty:kABLastNameProperty];
            
        if (firstName && lastName)
        {
            displayName = [NSString stringWithFormat:@"%@|%@", lastName, firstName];
        }
        else
        {
            displayName = [self displayName];
        }
    }
    
    return displayName;
}

//
// displayName
//
// Return a displayable name for the record.
// - If a group, return the group name.
// - If shown as a company, use the company name.
// - If shown as a person, use the ordering preference
//   to combine the name fields
//
-(NSString*)displayName 
{
    NSString* displayName = @"<No Name>";
    
    if ([self isGroup])
    {
        displayName = [self valueForProperty:kABGroupNameProperty];
    }
    else if ([self showAsCompany])
    {
        // If a company, use the company name
        NSString *companyName = [self valueForProperty:kABOrganizationProperty];
        
        if (companyName != nil)
        {
            displayName = companyName;
        }
    }
    else if ([self showAsPerson])
    {
        NSString *firstName = [self valueForProperty:kABFirstNameProperty];
        NSString *lastName = [self valueForProperty:kABLastNameProperty];
            
        if (firstName && lastName)
        {
            if ([self nameOrdering] == kABLastNameFirst)
            {
                displayName = [NSString stringWithFormat:@"%@, %@", lastName, firstName];
            }
            else
            {
                displayName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            }
        }
        else if (firstName && !lastName)
        {
            displayName = firstName;
        }
        else if (!firstName && lastName)
        {
            displayName = lastName;
        }
    }
    
    return displayName;
}

//
// sortName
//
// Returns a string by which the contact should be sorted,
// regardless of how the contact will ultimately by displayed
//
-(NSString*)sortName
{
    // Fall back to the display name
    NSString* sortName = [self displayName];
    
    if ([self showAsPerson])
    {
        NSString *firstName = [self valueForProperty:kABFirstNameProperty];
        NSString *lastName = [self valueForProperty:kABLastNameProperty];
        
        if (firstName && lastName)
        {
            //if ([self nameOrdering] == kABLastNameFirst)
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kABSortByLastName])
            {
                sortName = [NSString stringWithFormat:@"%@ %@", lastName, firstName];
            }
            else
            {
                sortName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            }
        }
    }

    return sortName;
}

//
// isGroup
//
// Parse the unique id looking to see if the ABRecord is a group
//
-(BOOL)isGroup 
{
    NSString *uid = [self uniqueId];
    
    return ([uid hasSuffix:@"ABGroup"] || [uid hasSuffix:@"ABSmartGroup"]);
}

//
// isSmartGroup
//
// Parse the unique id looking to see if the ABRecord is a smart group
//
-(BOOL)isSmartGroup
{
    NSString *uid = [self uniqueId];
    
    return [uid hasSuffix:@"ABSmartGroup"];
}

//
// isPerson
//
// Parse the unique id looking to see if the ABRecord is a person
//
-(BOOL)isPerson 
{
    NSString *uid = [self uniqueId];
    
    return ([uid hasSuffix:@"ABPerson"]);
}

//
// showAsPerson
//
// Return whether the record's 'ShowAsPerson' flag is set
//
-(BOOL)showAsPerson
{
    return ([[self valueForProperty:kABPersonFlags] intValue] & kABShowAsMask) == kABShowAsPerson;
}

//
// showAsCompany
//
// Return whether the record's 'ShowAsCompany' flag is set
//
-(BOOL)showAsCompany
{
    return ([[self valueForProperty:kABPersonFlags] intValue] & kABShowAsMask) == kABShowAsCompany;
}
                
//
// nameOrdering
//
// Returns kABFirstNameFirst or kABLastNameFirst.
// Need to check if the record has the default ordering overridden.
//
-(NSInteger)nameOrdering
{
    NSInteger defaultOrder = [[ABAddressBook sharedAddressBook] defaultNameOrdering];
    NSInteger recordOrder = [[self valueForProperty:kABPersonFlags] intValue] & kABNameOrderingMask;
    
    return (recordOrder != kABDefaultNameOrdering) ? recordOrder : defaultOrder;
}

//
// smallImage
//
// Return a small image suitable for use in a menu
// 
-(NSImage*)smallImage
{
    NSImage* image = nil;
    
    if ([self showAsCompany])
    {
        image = [NSImage imageNamed:@"company"];
    }
    else if ([self isSmartGroup])
    {
        image = [NSImage imageNamed:@"smartgroup"];
    }
    else if ([self isGroup])
    {
        image = [NSImage imageNamed:@"group"];
    }
    else if ([[ABAddressBook sharedAddressBook] recordForUniqueId:[self uniqueId]] == nil)
    {
        image = [NSImage imageNamed:@"bonjour"];
    }
    
    return image;
}

//
// displayNameComparison
//
// Compare the display names
//
-(NSComparisonResult)displayNameComparison:(ABRecord *)otherRecord
{
    return [[self displayName] caseInsensitiveCompare:[otherRecord displayName]];
}

//
// sortOrderComparison
//
// Compare based or sorting preferences
//
-(NSComparisonResult)sortOrderComparison:(ABRecord *)otherRecord
{
    return [[self sortName] localizedCaseInsensitiveCompare:[otherRecord sortName]];
}


@end
