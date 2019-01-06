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

-(BOOL)receiveContact {
    long dataCount = MAX_DATA_LENGTH;
    char data[dataCount];
    NSMutableData *incomingData = [NSMutableData data];
    long receiveDataLength;
    while ((receiveDataLength = [incomingSocket receiveBytes:data limit:dataCount]) > 0) {
        [incomingData appendBytes:data length:receiveDataLength];
    }
    if ([incomingData length] > 0 && !incomingSocket.lastError) {
        [receiveDelegate onContactReceivedSuccess:incomingData];
        incomingData = nil;
    } else {
        [receiveDelegate onContactReceiveError:incomingSocket.lastError];
        return NO;
        
    }
    return YES;
}



-(BOOL)initiateConnection:(NSString *)port timeOut:(int)timeOut {
    
    serverSocket = [[ServerSocket alloc] initWithPort:port];
    [serverSocket listen];
    incomingSocket = [serverSocket accept:timeOut];
    _isConnected = !serverSocket.isTimeOut && incomingSocket;
    if (!_isConnected) {
        [receiveDelegate onContactReceiveError:incomingSocket.lastError];
    }
    return _isConnected;
}

-(BOOL)closeConnection {
    return [incomingSocket close];
}

-(int)sendStatus:(NSString *)status {
    NSLog(@"send status ends");
    char *data;
    data = (char *) malloc(4);
    memset(data,' ',4);
    const char *statusByte = status.UTF8String;
    memcpy( &data[0], &statusByte[0], 4 );
    int sent_count = (int)[incomingSocket sendBytes:data count:4];
    free(data);
    return sent_count;
}

@end
