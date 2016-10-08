//
//  ABMenuBonjourController.h
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kABBonjourServiceType @"_abmenu._tcp."
#define kABBonjourUpdateNotification @"ABBonjourUpdateNotification"
#define kABBonjourViewCardNotification @"ABBonjourViewCardNotification"
#define kABBonjourDisplayName @"ABBonjourDisplayName"


@interface ABMenuBonjourController : NSObject<NSNetServiceDelegate, NSNetServiceBrowserDelegate, NSStreamDelegate>
{

    // Broadcasting
    NSNetService *netService;
    NSFileHandle *listeningSocket;
    
    // Listening
    NSNetServiceBrowser *browser;
    NSMutableArray *services;
    NSMutableData *currentDownload;
    
    // State
    BOOL isListening, isBroadcasting;
}

-(void)startBroadcasting;
-(void)stopBroadcasting;
-(void)startListening;
-(void)stopListening;

-(NSMenu*)serviceMenu;

@end
