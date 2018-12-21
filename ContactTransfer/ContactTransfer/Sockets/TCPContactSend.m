//
//  TCPContactSend.m
//  Contact Search
//
//  Created by Mostafizur Rahman on 8/10/16.
//  Copyright © 2016 Image-App. All rights reserved.
//

#import "TCPContactSend.h"

@interface TCPContactSend() {
    CSClientSocket *clientSocket;
}

@end

@implementation TCPContactSend

@synthesize sendDelegate;

- (instancetype)init {
    self = [super init];
    
    return self;
}


-(BOOL)initiateConnection:(NSString *)ipAddress
            incommingPort:(NSString *)port {
    clientSocket = [[CSClientSocket alloc] initWithHost:ipAddress port:port];
    _isConnected = [clientSocket connect];
    return _isConnected;
}

-(void)sendContactData:(NSData *)data {
    const int32_t dataLength = (int32_t)[data length];
    const int32_t sendLength = (int32_t)[clientSocket sendBytes:[data bytes] length:dataLength];
    if (sendLength >= 0) {
        [self.sendDelegate contactSendWithLen:sendLength];
    } else {
        [self.sendDelegate contactSendWithErr:clientSocket.lastError];
    }
}

-(BOOL)close {
    return [clientSocket close];
}

-(long)receiveStatus {
    char data[4];
    memset(data, ' ', 4);
    const long dataLength = [clientSocket receiveBytes:data length:4];
    if (dataLength > 0) {
        NSData* nsdata = [NSData dataWithBytes:(const void *)data length:4];
        const int count = [[[NSString alloc] initWithData:nsdata
                                           encoding:NSUTF8StringEncoding] intValue];
        [sendDelegate contactSendStatus:count];
    }
    return dataLength;
}

@end
