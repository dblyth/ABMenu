#import <Cocoa/Cocoa.h>

// Thanks to Dan Messing (Stunt Software) for this implementation
@interface NSBezierPath (PNRoundedRectangle)
+ (NSBezierPath*)bezierPathWithRoundRectInRect:(NSRect)aRect radius:(float)radius;
@end