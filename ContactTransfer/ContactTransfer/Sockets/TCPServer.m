//
//  ViewController.h
//  RingStudio iTransfer
//
//  Created by Mostafizur Rahman on 8/15/15.
//  Copyright (c) 2015 Dotsoft.inc.. All rights reserved.
//


#import "TCPServer.h"
#import "TCPClient.h"
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>
#import <CommonCrypto/CommonDigest.h>
#include <netdb.h>
#include <netinet/tcp.h>

@interface TCPServer ()
{
	int sockfd;
	int client_sockfd;
}

@end

@implementation TCPServer



#pragma mark Actions

- (BOOL)configureServerSocketWithPort:(NSString *) port
{
	
	[self close];
	
	struct addrinfo hints, *serverinfo, *p;
	
	bzero(&hints, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags = AI_PASSIVE;
	hints.ai_addr = NULL;
	hints.ai_protocol = 0;          /* Any protocol */
	hints.ai_canonname = NULL;
	hints.ai_next = NULL;
	
	struct timeval timeoutValue;
	timeoutValue.tv_sec = 10;
	timeoutValue.tv_usec = 0;
	
	BOOL res = NO;
	
	int error = getaddrinfo(NULL, [port UTF8String], &hints, &serverinfo);
	if (error)
    {
		[self close];
		return NO;
	}
	@try
    {
		for (p = serverinfo; p != NULL; p = p->ai_next)
        {
			if ((sockfd = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) < 0)
            {
				[self close];
				return NO;
			}
			if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int)) < 0)
            {
				[self close];
				return NO;
			}
			
			struct timeval timeout;
			timeout.tv_sec = 10;
			timeout.tv_usec = 0;
			
			if (setsockopt (sockfd, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout,
							sizeof(timeout)) < 0)
				perror("setsockopt failed\n");
//
//			if (setsockopt (sockfd, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout,
//							sizeof(timeout)) < 0)
//				perror("setsockopt failed\n");
			
//			if (setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeoutValue,
//						   sizeof(timeoutValue)) < 0)
//				perror("setsockopt failed\n");
			
			if (bind(sockfd, p->ai_addr, p->ai_addrlen) < 0)
            {
				[self close];
				
				
				continue;
			}else{
			res = YES;
			}
			
			break;
		}
		if (p == NULL)
        {
			[self close];
			return NO;
		}
	}
	@finally {
		freeaddrinfo(serverinfo); // All done with this structure.
	}
	
	if(!res){
		[self close];
		return NO;
	}
	
	if (listen(sockfd, 10) == -1)
    {
		[self close];
		return NO;
	}
	return YES;
}


-(int) getBoundClientSocket{

	struct sockaddr_storage remoteAddr;
	client_sockfd = accept(sockfd, (struct sockaddr *)&remoteAddr, &(socklen_t){sizeof(remoteAddr)});
	if (client_sockfd == -1)
	{
		[self close];
		return -1;
	}
	
	if (setsockopt(client_sockfd, SOL_SOCKET, SO_NOSIGPIPE, &(int){1}, sizeof(int)) < 0)
	{
		[self close];
		return -1;
	}
//	if (setsockopt(client_sockfd, IPPROTO_TCP,TCP_NODELAY, &(int){1}, sizeof(int)) < 0)
//	{
//		[self close];
//		return -1;
//	}
//	if (setsockopt(client_sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeoutValue,
//				   sizeof(timeoutValue)) < 0)
//		perror("setsockopt failed\n");

	return client_sockfd;
}


- (NSData *)receiveBytes
{

	int clientSocket = [self getBoundClientSocket];
	
	if (clientSocket < 0) {
		return NULL;
	}
	
	void *_buffer;
	long _size;
	
	_size = 2048;
	_buffer = valloc(_size);
	
	NSMutableData *concatenatedData = [[NSMutableData alloc] init];
	long received = 0; long len;
	while (( received = recv(clientSocket, _buffer, _size, 0)) > 0)
	{
		NSData *dt = [[NSData alloc] initWithBytes:_buffer length: received];
		len +=  received;
		[concatenatedData appendData:dt];
	}
	[self close];
	NSData *imageData = [[NSData alloc] initWithBytes:[concatenatedData bytes]  length:len];
	
	
	
	if (received < 0) {
		return NULL;
	}
	return imageData;
	
}

-(void)close{

	int c = close(sockfd);
	int c2 = close(client_sockfd);
	
	NSLog(@"TCP Close:%d,%d,%d,%d",sockfd,c,client_sockfd,c2);
}

@end
