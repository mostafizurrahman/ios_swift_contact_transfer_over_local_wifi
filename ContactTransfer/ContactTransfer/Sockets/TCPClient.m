//
//  ViewController.h
//  RingStudio iTransfer
//
//  Created by Mostafizur Rahman on 8/15/15.
//  Copyright (c) 2015 Dotsoft.inc. All rights reserved.
//


#import "TCPClient.h"
#import <CommonCrypto/CommonDigest.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <unistd.h>



@interface TCPClient(){


	int _sockfd;
}

@end


@implementation TCPClient


#pragma mark Actions

- (BOOL)configureClientSocketWithPort:(NSString *)_port Ip:(NSString *) _host
{
	struct addrinfo hints, *serverinfo, *p;
	bzero(&hints, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = 0;  
	hints.ai_flags = 0;
	
	int error = getaddrinfo([_host UTF8String], [_port UTF8String], &hints, &serverinfo);
	if (error)
    {
		_lastError = NEW_ERROR(error, gai_strerror(error));
		return NO;
	}
	@try
    {
		for (p = serverinfo; p != NULL; p = p->ai_next)
        {
			if ((_sockfd = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) < 0)
            {
				_lastError = NEW_ERROR(errno, strerror(errno));
				return NO;
			}
            
			if (setsockopt(_sockfd, SOL_SOCKET, SO_NOSIGPIPE, &(int){1}, sizeof(int)) < 0)
            {
				_lastError = NEW_ERROR(errno, strerror(errno));
				return NO;
			}
			
            if (setsockopt(_sockfd, IPPROTO_TCP, TCP_NODELAY, &(int){1}, sizeof(int)) < 0)
            {
				_lastError = NEW_ERROR(errno, strerror(errno));
				return NO;
			}
						
            if (connect(_sockfd, p->ai_addr, p->ai_addrlen) < 0)
            {
                _lastError = NEW_ERROR(errno, strerror(errno));
                continue;
            }
			break;
		}
		if (p == NULL) {
			_lastError = NEW_ERROR(1, "Could not contact server");
			return NO;
		}
	}
	@finally {
		freeaddrinfo(serverinfo);
	}
	return YES;
}


- (BOOL)sendBytes:(NSData *) buf {
	long sent;
	if ((sent = send(_sockfd, [buf bytes], buf.length, 0)) <= 0) {
		_lastError = NEW_ERROR(errno, strerror(errno));
		close(_sockfd);
	}
	
	close(_sockfd);
    return (sent > 0 ? YES : NO);
}




@end

