//
//  ViewController.h
//  RingStudio iTransfer
//
//  Created by Mostafizur Rahman on 8/15/15.
//  Copyright (c) 2015 Mac-12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TCPClient;
@interface TCPServer : NSObject {
@protected
//	long timeout;
}

#pragma mark - Properties


- (BOOL)configureServerSocketWithPort:(NSString *) port;
- (NSData *)receiveBytes;
- (void)close;


@end
