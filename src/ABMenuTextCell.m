//
//  ABMenuTextCell.m
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import "ABMenuTextCell.h"


@implementation ABMenuTextCell

-(NSRect)drawingRectForBounds:(NSRect)theRect
{	
	NSRect centeredRect;
		
    centeredRect.size.width = theRect.size.width;
    centeredRect.size.height = ([[self font] pointSize]) + 6;
    centeredRect.origin.x = theRect.origin.x;
    centeredRect.origin.y = theRect.origin.y + (theRect.size.height/2) - (centeredRect.size.height/2);
    
    return centeredRect;
}

@end
