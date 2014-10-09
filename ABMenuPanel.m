//
//  ABMenuPanel.m
//  ABMenu3
//
//  Created by David Blyth on 7/13/08.
//  Copyright 2008. All rights reserved.
//

#import "ABMenuPanel.h"


@implementation ABMenuPanel

-(id)init
{
    return ((self = [super init]));
}

-(void)keyDown:(NSEvent *)theEvent
{
    // Pass on the keyDown information to the delegate
    if ([self delegate])
    {
        [[self delegate] performSelector:@selector(keyDown:) withObject:theEvent];
    }
}

@end
