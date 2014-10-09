#import "ABTransparentView.h"
#import "ABRoundedRectangle.h"
#import "ABMenuController.h"

@implementation ABTransparentView

#define ROUNDED_RECT_RADIUS 30

#pragma mark -
#pragma mark *** NSView ***

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) 
    {

	}
	return self;
}

-(void)awakeFromNib
{
    [self setNeedsDisplay:YES];
}


-(void)drawRect:(NSRect)rect
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABUseHUDCardInterface] == YES)
    {
        // Erase whatever graphics were there before with clear
        [[NSColor clearColor] set];
        NSRectFill([self frame]);

        // Draw a simple black rectangle for the window
        [[NSColor blackColor] set];
        NSBezierPath* thePath = [NSBezierPath bezierPathWithRoundRectInRect:[self bounds] radius:15.0];
	
        // Draw the bezier path
        [thePath fill];
    }
}

@end
