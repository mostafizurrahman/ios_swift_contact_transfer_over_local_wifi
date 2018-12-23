//
//  ViewController.h
//  RingStudio iTransfer
//
//  Created by Mostafizur Rahman on 8/15/15.
//  Copyright (c) Dotsot.inc. All rights reserved.
//


#import "CSClientSocket.h"
#import <CommonCrypto/CommonDigest.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <unistd.h>
#include <sys/time.h>
#import <ifaddrs.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>


@interface CSClientSocket()
{
    @public
    Boolean isTimeout;
@protected
    void *_buffer;
    long _size;
    long _timeout;
    int _segmentSize;
}
@end


@implementation CSClientSocket

- (id)initWithHost:(NSString *)remoteHost andPort:(NSString *)remotePort
{
    if ((self = [super init]))
    {
        _sockfd = 0;
        _host = [remoteHost copy];
        _port = [remotePort copy];
        _size = getpagesize() * 1448 / 4;
        _buffer = valloc(_size);
    }
    return self;
}

- (id)initWithFileDescriptor:(int)fd
{
    if ((self = [super init]))
    {
        _sockfd = fd;
        _size = getpagesize() * 1448 / 4;
        _buffer = valloc(_size);
        if (setsockopt(_sockfd, SOL_SOCKET, SO_NOSIGPIPE, &(int){1}, sizeof(int)) < 0)
        {
            _lastError = NEW_ERROR(errno, strerror(errno));
            return nil;
        }
        if (setsockopt(_sockfd, IPPROTO_TCP, TCP_NODELAY, &(int){1}, sizeof(int)) < 0)
        {
            _lastError = NEW_ERROR(errno, strerror(errno));
            return nil;
        }
    }
    return self;
}

- (void)buffer:(void **)outBuf size:(long *)outSize
{
    if (outBuf && outSize)
    {
        *outBuf = _buffer;
        *outSize = _size;
    }
}

- (void)dealloc
{
    [self close];
    free(_buffer);
}

#pragma mark Actions

- (BOOL)connect
{
    return [self connect:0];
}

- (BOOL)connect:(long)nsec
{
    struct addrinfo hints, *serverinfo, *p;
    bzero(&hints, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
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
    @finally
    {
        freeaddrinfo(serverinfo);
    }
    return YES;
}


- (BOOL)close
{
    if (_sockfd > 0 && close(_sockfd) < 0)
    {
        _lastError = NEW_ERROR(errno, strerror(errno));
        return NO;
    }
    _sockfd = 0;
    return YES;
}

- (long)sendBytes:(const void *)buf count:(long)count
{
    long sent;
    if ((sent = send(_sockfd, buf, count, 0)) < 0) {
        _lastError = NEW_ERROR(errno, strerror(errno));
    }
    return sent;
}

- (long)receiveBytes:(void *)buf limit:(long)limit
{
    struct timeval tv;
    tv.tv_sec = 5;
    tv.tv_usec = 0;
    fd_set read_fds;
    FD_ZERO(&read_fds);
    FD_SET(_sockfd, &read_fds);
    int retVal = select(_sockfd+1, &read_fds, NULL, NULL, &tv);
    if (retVal > 0)
    {
        long received = recv(_sockfd, buf, limit, 0);
        if (received < 0)
        {
            _lastError = NEW_ERROR(errno, strerror(errno));
            
        }
        return received;
    }
    return -1;
}


@end

