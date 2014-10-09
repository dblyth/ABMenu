//
//  ABMenuPersonAdditions.m
//  ABMenu3
//
//  Created by David Blyth on 1/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ABMenuPersonAdditions.h"


@implementation ABPerson (ABMenuNameAdditions)

-(NSString *)displayName
{
    if ([[self valueForProperty:kABPersonFlags] intValue] == kABShowAsPerson) 
    {
        NSString *firstName = [self valueForProperty:kABFirstNameProperty];
        NSString *lastName = [self valueForProperty:kABLastNameProperty];
        
        if (firstName && lastName)
        {
            if ([[ABAddressBook sharedAddressBook] defaultNameOrdering] == kABLastNameFirst)
                return [NSString stringWithFormat:@"%@, %@", lastName, firstName];
            else
                return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        }
        else if (firstName && !lastName)
            return firstName;
        else if (!firstName && lastName)
            return lastName;
        else
            return @"<No Name>";
    }
    else if ([[self valueForProperty:kABPersonFlags] intValue] & kABShowAsCompany)
    {
        NSString *companyName = [self valueForProperty:kABOrganizationProperty];
        return companyName ? companyName : @"<No Name>";
    }
    else
    {
        return @"No Name";
    }
}

@end
