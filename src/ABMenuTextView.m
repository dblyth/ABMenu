//
//  ABMenuInfoTableView.m
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import "ABMenuTextView.h"

@implementation ABMenuTextView

-(void)setHudStyle:(BOOL)flag
{
    hudStyle = flag;
    
    if (hudStyle)
    {
        [self setTextColor:[NSColor whiteColor]];
    }
    else
    {
        [self setTextColor:[NSColor blackColor]];
    }
}

-(void)awakeFromNib
{
    [[self enclosingScrollView] setDrawsBackground:NO];
	[self setDrawsBackground:NO];
}

@end
