//
//  TCPContactSend.h
//  Contact Search
//
//  Created by Mostafizur Rahman on 8/10/16.
//  Copyright © 2016 Dotsoft.inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSClientSocket.h"
#import "ServerSocket.h"

@protocol ContactSendDelegate <NSObject>
-(void)contactSendWithLen:(int)dataLength;
-(void)contactSendWithErr:(NSError *)sendError;
-(void)contactSendStatus:(int)count;
@end

@interface TCPContactSend : NSObject

@property (readonly)            BOOL isConnected;
@property (weak, readwrite)     id<ContactSendDelegate> sendDelegate;


-(void) sendContactData:(NSData *)data;
-(BOOL) close;
-(long) receiveStatus;
-(BOOL) initiateConnection:(NSString *)ipAddress
             incommingPort:(NSString *)port;

@end
