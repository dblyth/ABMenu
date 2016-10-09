//
//  ABMenuBonjourController.m
//  ABMenu3
//
//  Created by David Blyth on 6/26/08.
//  Copyright 2008. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "ABMenuBonjourController.h"
#import "ABRecordAdditions.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>


@implementation ABMenuBonjourController

#pragma mark -
#pragma mark *** NSObject ***

-(id)init
{
    isListening = isBroadcasting = NO;
    
    return ((self = [super init]));
}

-(void)dealloc
{
    [self stopBroadcasting];
    [self stopListening];
    
    [super dealloc];
}

-(NSMenu *)serviceMenu
{    
    NSMenu *bonjourMenu = [[NSMenu alloc] initWithTitle:@"bonjour"];
    
    NSEnumerator *enumerator = [services reverseObjectEnumerator];
    NSNetService *service;
    NSMutableArray *dictArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    // Create an array of the display names of the services, depending on the user's preference
    while ((service = [enumerator nextObject]))
    {
        NSScanner *scanner = [NSScanner scannerWithString:[service name]];
        NSString *lastName, *firstName, *displayName;
        
        // Scan for the first and last name elements
        [scanner scanUpToString:@"|" intoString:&lastName];
        if ([scanner isAtEnd])
            firstName = @"";
        else
        {
            [scanner scanString:@"|" intoString:nil];
            [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@""] intoString:&firstName];
        }
        
        // Reform the elements based on the user's preference. This is why we can't do it on the server side
        if (firstName)
        {
            if ([[ABAddressBook sharedAddressBook] defaultNameOrdering] == kABLastNameFirst)
                displayName = [NSString stringWithFormat:@"%@, %@", lastName, firstName];
            else
                displayName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        }
        else if (lastName)
            displayName = lastName;
        else
            displayName = @"<No Name>";
        
        NSDictionary *serviceDict = [NSDictionary dictionaryWithObjectsAndKeys:displayName, @"displayName", service, @"service", nil];
        
        [dictArray addObject:serviceDict];
    }
    
    // Now sort the names and add to the menu
    enumerator = [[[NSMutableArray arrayWithArray:dictArray] sortedArrayUsingDescriptors:
                   [NSArray arrayWithObject:
                    [[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES] autorelease]]] objectEnumerator];
    NSDictionary *dict;
    
    while ((dict = [enumerator nextObject]))
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[dict valueForKey:@"displayName"] action:@selector(viewBonjourCard:) keyEquivalent:@""];
        [item setRepresentedObject:[dict valueForKey:@"service"]];
        [item setTarget:self];
        [item setImage:[NSImage imageNamed:@"bonjour"]];
        [bonjourMenu addItem:item];
        [item release];
    }
    
    [dictArray release];
    
    return bonjourMenu;
}

-(IBAction)viewBonjourCard:(id)sender {
    
    // Download the data
    NSNetService * service = [sender representedObject];
    
    if (service != nil)
    {
        NSInputStream * datastream;
        [service getInputStream:&datastream outputStream:nil];
        [datastream retain];
        [datastream setDelegate:self];
        [datastream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [datastream open];
    }
}

#pragma mark -
#pragma mark *** ABMenuBonjourController ***

-(void)startBroadcasting
{
    int fd;
    struct sockaddr_in addr;
    socklen_t namelen = sizeof(addr);
    uint16_t port = 0;
    
    if (isBroadcasting)
    {
        return;
    }
    
    // Create the socket
    fd = socket(AF_INET, SOCK_STREAM, 0);
    
    if(fd > 0)
    {
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_ANY);
        addr.sin_port = 0;
        
        if(bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
        {
            close(fd);
            return;
        }
        
        if(getsockname(fd, (struct sockaddr *)&addr, &namelen) < 0) {
            close(fd);
            return;
        }
        
        port = ntohs(addr.sin_port);
        
        if(listen(fd, 1) == 0)
        {
            listeningSocket = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
        }
        else
        {
            return;
        }
        
        netService = [[NSNetService alloc] initWithDomain:@"" type:kABBonjourServiceType name:[[[ABAddressBook sharedAddressBook] me] parsableDisplayName] port:port];
        [netService setDelegate:self];
        
        // Start broadcasting
        [listeningSocket acceptConnectionInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionReceived:) name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
        [netService publish];
        
        isBroadcasting = YES;
    }
}

-(void)stopBroadcasting
{    
    if (!isBroadcasting)
    {
        return;
    }
    
    // Kill the service and socket so it can be completely restarted later
    [netService stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
    isBroadcasting = NO;
}

-(void)startListening 
{
    if (isListening)
    {
        return;
    }
    
    browser = [[NSNetServiceBrowser alloc] init];
    services = [[NSMutableArray array] retain];
    [browser setDelegate:self];
    
    [browser searchForServicesOfType:kABBonjourServiceType inDomain:@""];
    isListening = YES;
}

-(void)stopListening {
    
    if (!isListening)
    {
        return;
    }
    
    [services release];
    [browser stop];
    isListening = NO;
}

#pragma mark -
#pragma mark *** Callbacks ***

- (void)connectionReceived:(NSNotification *)aNotification
{
    NSFileHandle * incomingConnection = [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    NSData * representationToSend = [[[ABAddressBook sharedAddressBook] me] vCardRepresentation];
    [[aNotification object] acceptConnectionInBackgroundAndNotify];
    [incomingConnection writeData:representationToSend];
    [incomingConnection closeFile];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)event 
{
    switch(event) 
    {
        case NSStreamEventHasBytesAvailable:
            
            if (!currentDownload)
            {
                currentDownload = [[NSMutableData alloc] initWithCapacity:0];
            }
            
            uint8_t readBuffer[4096];
            NSInteger amountRead = 0;
            NSInputStream * is = (NSInputStream *)aStream;
            amountRead = [is read:readBuffer maxLength:4096];
            [currentDownload appendBytes:readBuffer length:amountRead];
            break;
            
        case NSStreamEventEndEncountered:
            [(NSInputStream *)aStream close];
            
            ABRecord *record = [[ABPerson alloc] initWithVCardRepresentation:currentDownload];
            [[NSNotificationCenter defaultCenter] postNotificationName:kABBonjourViewCardNotification object:record];
            
            [currentDownload release];
            currentDownload = nil;
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark *** NSNetService Delegate ***

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    // In case of error, stop broadcasting
    [self stopBroadcasting];
}

- (void)netServiceDidStop:(NSNetService *)sender 
{   
    [netService release];
    netService = nil;
    [listeningSocket release];
    listeningSocket = nil;
}

#pragma mark -
#pragma mark *** NSNetServiceBrowser Delegate ***

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing 
{
    [services addObject:aNetService];
    [aNetService resolveWithTimeout:5.0];
    
    if(!moreComing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kABBonjourUpdateNotification object:nil];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing 
{
    [services removeObject:aNetService];
    
    if(!moreComing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kABBonjourUpdateNotification object:nil]; 
    }
}

@end
