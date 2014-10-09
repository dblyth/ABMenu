//
//  ABMenuInfoTableView.h
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTableView (ContextualPopupMenu)
-(NSMenu *)tableView:(NSTableView *)aTableView menuForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
@end

@interface ABMenuInfoTableView : NSTableView
{
	BOOL hudStyle;
}

-(void)setHudStyle:(BOOL)flag;
-(void)styleCell:(NSTextFieldCell *)cell;

@end
