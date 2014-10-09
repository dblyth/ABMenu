#import "ABCardWindow.h"
#import "ABMenuController.h"

@implementation ABCardWindow

#pragma mark -
#pragma mark *** NSWindow ***

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	    
    NSWindow *window;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABUseHUDCardInterface] == YES)
    {
        window = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	
        [window setBackgroundColor:[NSColor clearColor]];
        [window setAlphaValue:0.7];
        [window setOpaque:NO];
        [window setHasShadow:YES];
    }
    else
    {
        window = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    }
    
    [window setLevel:NSFloatingWindowLevel];
	
	return window;
}

- (BOOL) canBecomeKeyWindow
{
    return YES;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABUseHUDCardInterface] == YES)
    {
        NSPoint currentLocation;
        NSPoint newOrigin;
        NSRect  screenFrame = [[NSScreen mainScreen] frame];
        NSRect  windowFrame = [self frame];
	
        //grab the current global mouse location; we could just as easily get the mouse location 
        //in the same way as we do in -mouseDown:
        currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
        newOrigin.x = currentLocation.x - initialLocation.x;
        newOrigin.y = currentLocation.y - initialLocation.y;
    
        // Don't let window get dragged up under the menu bar
        if( (newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height) ){
            newOrigin.y=screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
        }
    
        //go ahead and move the window to the new location
        [self setFrameOrigin:newOrigin];
    }
}

//We start tracking the a drag operation here when the user first clicks the mouse,
//to establish the initial location.
- (void)mouseDown:(NSEvent *)theEvent
{    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kABUseHUDCardInterface] == YES)
    {
        NSRect  windowFrame = [self frame];
	
        //grab the mouse location in global coordinates
        initialLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
        initialLocation.x -= windowFrame.origin.x;
        initialLocation.y -= windowFrame.origin.y;
    }
}


@end
