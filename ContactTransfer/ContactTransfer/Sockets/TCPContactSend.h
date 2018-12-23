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

@protocol TCPSendContactDelegate <NSObject>
-(void)onContactSendSuccess:(int)length;
-(void)onContactSendError:(NSError *)sendError;
-(void)onSendStatusReceived:(int)count;
@end

@interface TCPContactSend : NSObject

@property (readonly)            BOOL isConnected;
@property (weak, readwrite)     id<TCPSendContactDelegate> sendDelegate;


-(void) sendContact:(NSData *)data;
-(BOOL) close;
-(long)  receiveStatus;
-(BOOL) initiateConnection:(NSString *)ipAddress incommingPort:(NSString *)port;

@end
