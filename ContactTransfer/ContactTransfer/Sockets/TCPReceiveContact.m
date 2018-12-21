//
//  TCPReceiveContact.m
//  Contact Search
//
//  Created by Mostafizur Rahman on 8/10/16.
//  Copyright © 2016 Dotsoft.inc.. All rights reserved.
//

#import "TCPReceiveContact.h"

@interface TCPReceiveContact(){
    ServerSocket *serverSocket;
}

@end

@implementation TCPReceiveContact
@synthesize receiveDelegate;

-(void)receiveContact
{
    long dataCount = MAX_DATA_LENGTH;
    char data[dataCount];
    NSMutableData *incomingData = [NSMutableData data];
    long receiveDataLength;
    while ((receiveDataLength = [incomingSocket receiveBytes:data limit:dataCount]) > 0)
    {
        [incomingData appendBytes:data length:receiveDataLength];
    }
    if ([incomingData length] && !incomingSocket.lastError)
    {
        [receiveDelegate onContactReceivedSuccess:incomingData];
        incomingData = nil;
    }
    else
    {
        
        NSLog(@"error starts");
        [receiveDelegate onContactReceiveError:incomingSocket.lastError];
        
        NSLog(@"error ends");
        
    }
}



-(BOOL)initiateConnection:(NSString *)port timeOut:(int)timeOut
{
    
    serverSocket = [[ServerSocket alloc] initWithPort:port];
    [serverSocket listen];
    incomingSocket = [serverSocket accept:timeOut];
    _isConnected = !serverSocket.isTimeOut && incomingSocket;
    if (!_isConnected)
    {
        [receiveDelegate onContactReceiveError:incomingSocket.lastError];
        NSLog(@"time out occured thanks");
    }
    return _isConnected;
}

-(BOOL)closeConnection
{
    return [incomingSocket close];
}

-(int)sendStatus:(NSString *)status
{
    NSLog(@"send status ends");
    char *data;
    data = (char *) malloc(4);
    memset(data,' ',4);
    const char *statusByte = status.UTF8String;
    memcpy( &data[0], &statusByte[0], 4 );
    return (int)[incomingSocket sendBytes:data count:4];//freee dataa
}

@end
