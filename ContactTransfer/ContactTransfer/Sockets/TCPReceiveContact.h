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
#define MAX_DATA_LENGTH 8192

@protocol ReceiveContactDelegate <NSObject>

-(void)contactReceivedWithData:(NSData *)data;
-(void)contactReceiveWithError:(NSError *)receiveError;
@end
@interface TCPReceiveContact : NSObject {
    
}

@property (weak, readwrite) id<ReceiveContactDelegate> receiveDelegate;

@property (readonly)        BOOL isConnected;

-(void) receiveContact;
-(BOOL) initiateConnection:(NSString *)port timeOut:(int)timeOut;
-(int)  sendStatus:(NSString *)status;
@end
