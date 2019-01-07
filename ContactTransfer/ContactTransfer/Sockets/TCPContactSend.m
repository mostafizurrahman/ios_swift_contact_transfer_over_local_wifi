//
//  TCPContactSend.m
//  Contact Search
//
//  Created by Mostafizur Rahman on 8/10/16.
//  Copyright © 2016 Dotsoft.inc. All rights reserved.
//

#import "TCPContactSend.h"

@interface TCPContactSend() {
    CSClientSocket *clientSocket;
    int failCount;
}

@end

@implementation TCPContactSend

@synthesize sendDelegate;

-(void)sendContact:(NSData *)data {
    
    unsigned long contactDataLength = [data length];
    unsigned long sendDataLength = [clientSocket sendBytes:[data bytes] count:contactDataLength];
    if (sendDataLength >= 0) {
        [sendDelegate onContactSendSuccess:sendDataLength];
    } else {
        [sendDelegate onContactSendError:clientSocket.lastError];
    }
}

-(BOOL)initiateConnection:(NSString *)ipAddress incommingPort:(NSString *)port {
    clientSocket = [[CSClientSocket alloc] initWithHost:ipAddress andPort:port];
    _isConnected = [clientSocket connect];
    return _isConnected;
}

-(BOOL)close {
    return [clientSocket close];
}

-(long)receiveStatus {
    char data[4] = {};
    long dataLength = [clientSocket receiveBytes:data limit:4];
    if (dataLength > 0) {
        NSData* nsdata = [NSData dataWithBytes:(const void *)data length:4];
        int count = [[[NSString alloc] initWithData:nsdata encoding:NSUTF8StringEncoding] intValue];
        [sendDelegate onSendStatusReceived:count];
    }
    return dataLength;
}

@end
