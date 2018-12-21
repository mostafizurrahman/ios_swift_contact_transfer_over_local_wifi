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
    CSClientSocket *incomingSocket;
}

@end

@implementation TCPReceiveContact
@synthesize receiveDelegate;

-(instancetype)init{
    self = [super init];
    return self;
}

-(BOOL)initiateConnection:(NSString *)port timeOut:(int)timeOut {
    
    serverSocket = [[ServerSocket alloc] initWithPort:port];
    [serverSocket listen];
    incomingSocket = [serverSocket accept:timeOut];
    _isConnected = !serverSocket.isTimeOut && incomingSocket;
    if (!_isConnected) {
        [self.receiveDelegate contactReceiveWithError:incomingSocket.lastError];
    }
    return _isConnected;
}

-(void)receiveContact {
    const long dataCount = MAX_DATA_LENGTH;
    char data[dataCount];
    NSMutableData *incomingData = [NSMutableData data];
    long dataLength = -1;
    while ((dataLength = [incomingSocket receiveBytes:data length:dataLength]) > 0) {
        [incomingData appendBytes:data length:dataLength];
    }
    if ([incomingData length] > 0 && !incomingSocket.lastError) {
        [self.receiveDelegate contactReceivedWithData:incomingData];
        incomingData = nil;
    } else  {
        [self.receiveDelegate contactReceiveWithError:incomingSocket.lastError];
    }
}

-(BOOL)closeConnection {
    return [incomingSocket close];
}

-(int)sendStatus:(NSString *)status {
    char *data;
    data = (char *) malloc(4);
    memset(data,' ',4);
    const char *statusByte = status.UTF8String;
    memcpy( data, statusByte, 4 );
    const long _ret_val = [incomingSocket sendBytes:data length:4];
    free(data);
    return (int)_ret_val;
}

@end
