//
//  TCPReceiveContact.h
//  Contact Search
//
//  Created by Mostafizur Rahman on 8/10/16.
//  Copyright © 2016 Dotsoft.inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSClientSocket.h"
#import "ServerSocket.h"
#define MAX_DATA_LENGTH 8000

@protocol TCPReceiveContactDelegate <NSObject>
-(void)onDataCountRead:(unsigned long)dataCount;
-(void)onContactReceivedSuccess:(NSData *)data;
-(void)onContactReceiveError:(NSError *)receiveError;
@end
@interface TCPReceiveContact : NSObject
{
    CSClientSocket *incomingSocket;
}
@property (weak, readwrite) id<TCPReceiveContactDelegate> receiveDelegate;
@property (readonly)        BOOL isConnected;

-(BOOL) receiveContact;
-(BOOL) initiateConnection:(NSString *)port timeOut:(int)timeOut;
-(int)  sendStatus:(NSString *)status;
@end
