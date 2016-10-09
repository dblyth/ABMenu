//
//  ABMenuInfoTableView.m
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import "ABMenuInfoTableView.h"
#import "ABMenuCardController.h"

@implementation ABMenuInfoTableView

// Thanks to Timothy Hatcher and www.cocoadev.com for how to do this
-(NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSPoint where;
	NSInteger row = -1;
	NSInteger col = -1;
	
	where = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	row = [self rowAtPoint:where];
	col = [self columnAtPoint:where];
	
	if (row >= 0)
	{
		NSTableColumn *column = nil;
		if (col >= 0)
			column = [[self tableColumns] objectAtIndex:col];
		
		if ([[self delegate] respondsToSelector:@selector(tableView:shouldSelectRow:)])
		{
			if ([[self delegate] tableView:self shouldSelectRow:row])
			{
                [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
			}
		}
		else
		{
            [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		}
				
        
        return [(ABMenuCardController*)[self dataSource] tableView:self menuForTableColumn: column row:row];
	}

	[self deselectAll:nil];
    
	return [self menu];
}

-(void)setHudStyle:(BOOL)flag
{
    hudStyle = flag;
    
    if (hudStyle)
    {
        [self setUsesAlternatingRowBackgroundColors:NO];
        [self setBackgroundColor:[NSColor blackColor]];
        [self setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
        [self setGridColor:[NSColor whiteColor]];
    }
    else
    {
        [self setUsesAlternatingRowBackgroundColors:YES];
        [self setGridStyleMask:NSTableViewGridNone];
    }
}

-(void)awakeFromNib
{
    [[self enclosingScrollView] setDrawsBackground:NO];
}

-(void)styleCell:(NSTextFieldCell *)cell
{
    if (hudStyle)
    {
        [cell setTextColor:[NSColor whiteColor]];
    }
    else
    {
        [cell setTextColor:[NSColor blackColor]];        
    }
}

- (BOOL)isOpaque 
{
    return NO;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
    
    if (hudStyle)
    {
        return;
    }
    else
    {
        [super drawBackgroundInClipRect:clipRect];
    }
}

@end
