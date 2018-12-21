//
//  ViewController.h
//  RingStudio iTransfer
//
//  Created by Mostafizur Rahman on 8/15/15.
//  Copyright (c) 2015 Mac-12. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CSClientSocket;
@interface ServerSocket : NSObject {
@protected
//	long timeout;
}

#pragma mark - Properties

@property (nonatomic, readonly) int sockfd;
@property (nonatomic, readonly) NSString *port;
@property (nonatomic, readonly) NSError *lastError;
@property (readonly) BOOL isTimeOut;
- (id)initWithPort:(NSString *)port __attribute__((nonnull));
- (BOOL)listen;
- (CSClientSocket *)accept:(int)timeOut;
- (BOOL)close;
@end
