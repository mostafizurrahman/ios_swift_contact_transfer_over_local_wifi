//
//  TCPContactSend.m
//  Contact Search
//
//  Created by Mostafizur Rahman on 8/10/16.
//  Copyright © 2016 Image-App. All rights reserved.
//

#import "TCPContactSend.h"

@interface TCPContactSend()
{
    
    CSClientSocket *clientSocket;
}

@end

@implementation TCPContactSend

@synthesize sendDelegate;

-(void)sendContact:(NSData *)data
{
    NSLog(@"send starts");
    int32_t contactDataLength = (int32_t)[data length];
    int32_t sendDataLength = (int32_t)[clientSocket sendBytes:[data bytes] count:contactDataLength];
    if (sendDataLength >= 0)
    {
        [sendDelegate onContactSendSuccess:sendDataLength];
    }
    else
    {
        [sendDelegate onContactSendError:clientSocket.lastError];
    }
    NSLog(@"send ends");
}

-(BOOL)initiateConnection:(NSString *)ipAddress incommingPort:(NSString *)port
{
    clientSocket = [[CSClientSocket alloc] initWithHost:ipAddress andPort:port];
    _isConnected = [clientSocket connect];
    return _isConnected;
}

-(BOOL)close
{
    return [clientSocket close];
}

-(long)receiveStatus
{
    char data[4];
    memset(data, ' ', 4);
    long dataLength = [clientSocket receiveBytes:data limit:4];
    if (dataLength > 0)
    {
        NSData* nsdata = [NSData dataWithBytes:(const void *)data length:4];
        int count = [[[NSString alloc] initWithData:nsdata encoding:NSUTF8StringEncoding] intValue];
        [sendDelegate onSendStatusReceived:count];
    }
    return dataLength;
}

@end
