//
//  ABMenuTextView.h
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ABMenuTextView : NSTextView
{
	BOOL hudStyle;
}

-(void)setHudStyle:(BOOL)flag;

@end
