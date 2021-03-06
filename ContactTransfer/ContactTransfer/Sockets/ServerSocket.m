//
//  ViewController.h
//  RingStudio iTransfer
//
//  Created by Mostafizur Rahman on 8/15/15.
//  Copyright (c) 2015 Dotsoft.inc. All rights reserved.
//


#import "ServerSocket.h"
#import "CSClientSocket.h"
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sys/time.h>
#import <ifaddrs.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@implementation ServerSocket

@synthesize sockfd;
@synthesize port;
@synthesize lastError;

- (id)initWithPort:(NSString *)localPort
{
	if ((self = [super init]))
    {
		port = [localPort copy];
	}
	return self;
}

- (void)dealloc
{
	[self close];
}

#pragma mark Actions

- (BOOL)listen
{
	struct addrinfo hints, *serverinfo, *p;
	
	bzero(&hints, sizeof(hints));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags = AI_PASSIVE;
	
	int error = getaddrinfo(NULL, [port UTF8String], &hints, &serverinfo);
	if (error)
    {
		lastError = NEW_ERROR(error, gai_strerror(error));
		return NO;
	}
	@try
    {
		for (p = serverinfo; p != NULL; p = p->ai_next)
        {
			if ((sockfd = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) < 0)
            {
				lastError = NEW_ERROR(errno, strerror(errno));
				return NO;
			}
			if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int)) < 0)
            {
				lastError = NEW_ERROR(errno, strerror(errno));
				return NO;
			}
			if (bind(sockfd, p->ai_addr, p->ai_addrlen) < 0)
            {
				close(sockfd);
				continue;
			}
            break;
		}
		if (p == NULL)
        {
			lastError = NEW_ERROR(errno, strerror(errno));
			return NO;
		}
	}
	@finally
    {
		freeaddrinfo(serverinfo); // All done with this structure.
	}
	
	if (listen(sockfd, 10) == -1)
    {
		lastError = NEW_ERROR(errno, strerror(errno));
		return NO;
	}
	return YES;
}

- (BOOL)close
{
	if (sockfd > 0 && close(sockfd) < 0)
    {
		lastError = NEW_ERROR(errno, strerror(errno));
		return NO;
	}
	sockfd = 0;
	return YES;
}

- (CSClientSocket *)accept:(int)timeOut
{
    _isTimeOut = false;
	struct sockaddr_storage remoteAddr;
    struct timeval tv;
    tv.tv_sec = timeOut;
    tv.tv_usec = 0;
    fd_set read_fds;
    FD_ZERO(&read_fds);
    FD_SET(sockfd, &read_fds);
    int retVal = select(sockfd+1, &read_fds, NULL, NULL, &tv);
    if (retVal > 0) {
        int clientfd = accept(sockfd, (struct sockaddr *)&remoteAddr, &(socklen_t){sizeof(remoteAddr)});
        return [[CSClientSocket alloc] initWithFileDescriptor:clientfd];
    }
    _isTimeOut = true;
    return nil;
}
+(NSString *)getBroadcastAddress {
    NSString * broadcastAddr = @"Error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    broadcastAddr = [NSString stringWithUTF8String:
                                     inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    if ([@"192.168.0.101" isEqualToString:broadcastAddr]){
        NSLog(@"fk");
    }
    return broadcastAddr;
}
@end
