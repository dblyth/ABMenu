//file://localhost/Users/david/Projects/Software/ABMenu3/ABRecordAdditions.m
//  ABRecordAdditions.h
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

@interface ABRecord (ABMenuRecordAdditions)

-(NSString*)displayName;
-(NSString*)parsableDisplayName;
-(NSString*)sortName;

-(BOOL)isGroup;
-(BOOL)isSmartGroup;
-(BOOL)isPerson;

-(BOOL)showAsPerson;
-(BOOL)showAsCompany;

-(int)nameOrdering;

-(NSImage*)smallImage;

-(NSComparisonResult)displayNameComparison:(ABRecord *)otherRecord;
-(NSComparisonResult)sortOrderComparison:(ABRecord *)otherRecord;

@end
