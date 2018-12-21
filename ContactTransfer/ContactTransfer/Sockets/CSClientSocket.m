//
//  ViewController.h
//  RingStudio iTransfer
//
//  Created by Mostafizur Rahman on 8/15/15.
//  Copyright (c) Image-App. All rights reserved.
//


#import "CSClientSocket.h"
#import <CommonCrypto/CommonDigest.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <unistd.h>
#include <sys/_select.h>


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
@property (nonatomic, readwrite) int client_socket;
@end


@implementation CSClientSocket

- (instancetype)initWithHost:(NSString *)remoteHost
              port:(NSString *)remotePort {
    
    if ((self = [super init])) {
        self.client_socket = 0;
        _host = [remoteHost copy];
        _port = [remotePort copy];
        _size = getpagesize() * 1448 / 4;
        _buffer = valloc(_size);
    }
    return self;
}

- (instancetype)initWithFileDescriptor:(int)socket {
    
    if ((self = [super init])) {
        self.client_socket = socket;
        _size = getpagesize() * 1448 / 4;
        _buffer = valloc(_size);
        if (setsockopt(self.client_socket,
                       SOL_SOCKET, SO_NOSIGPIPE,
                       &(int){1}, sizeof(int)) < 0) {               //set sigpipe options
            _lastError = NEW_ERROR(errno, strerror(errno));
            return nil;
        }
        if (setsockopt(self.client_socket, IPPROTO_TCP,
                       TCP_NODELAY, &(int){1}, sizeof(int)) < 0) { // set socket TCP options
            _lastError = NEW_ERROR(errno, strerror(errno));
            return nil;
        }
    }
    return self;
}

#pragma mark Actions
- (BOOL)connect {
    return [self connect:0];
}

- (BOOL)connect:(long)nsec {
    
    struct addrinfo hints, *server_info, *iterator = NULL;
    bzero(&hints, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    
    int error = getaddrinfo([_host UTF8String], [_port UTF8String], &hints, &server_info);
    if (error != 0) {
        _lastError = NEW_ERROR(error, gai_strerror(error));
        return NO;
    }
    @try {
        for (iterator = server_info; iterator != NULL; iterator = iterator->ai_next) {
            
            if ((self.client_socket = socket(iterator->ai_family,
                                                 iterator->ai_socktype,
                                                 iterator->ai_protocol)) < 0) {
                _lastError = NEW_ERROR(errno, strerror(errno));
                return NO;
            }
            
            if (setsockopt(self.client_socket, SOL_SOCKET,
                           SO_NOSIGPIPE, &(int){1}, sizeof(int)) < 0) {
                _lastError = NEW_ERROR(errno, strerror(errno));
                return NO;
            }
            
            if (setsockopt(self.client_socket, IPPROTO_TCP,
                           TCP_NODELAY, &(int){1}, sizeof(int)) < 0) {
                _lastError = NEW_ERROR(errno, strerror(errno));
                return NO;
            }
            
            if (connect(self.client_socket, iterator->ai_addr,
                        iterator->ai_addrlen) < 0) {
                _lastError = NEW_ERROR(errno, strerror(errno));
                continue;
            }
            break;
        }
        if (iterator == NULL) {
            _lastError = NEW_ERROR(1, "Could not contact server");
            return NO;
        }
    } @finally {
        freeaddrinfo(server_info);
    }
    return YES;
}

- (void)getBuffer:(char *)outBuffer size:(long *)outSize {
    
    memcpy(outBuffer, _buffer, _size);
    *outSize = _size;
}

- (void)dealloc {
    [self close];
    free(_buffer);
}

- (BOOL)close {
    
    if (self.client_socket > 0 &&
        close(self.client_socket) < 0) {
        _lastError = NEW_ERROR(errno, strerror(errno));
        return NO;
    }
    self.client_socket = 0;
    return YES;
}

- (long)sendBytes:(const char *)sendBuffer
            length:(const long)dataLength {
    
    long sent;
    if ((sent = send(self.client_socket,
                     sendBuffer, dataLength, 0)) < 0) {
        _lastError = NEW_ERROR(errno, strerror(errno));
    }
    return sent;
}

- (long)receiveBytes:(void *)outBuffer
              length:(const long)dataLength {
    
    struct timeval time_value;
    time_value.tv_sec = 2;
    time_value.tv_usec = 0;
    fd_set read_fds;
    FD_ZERO(&read_fds);
    FD_SET(self.client_socket, &read_fds);
    const int retVal = select(self.client_socket+1, &read_fds,
                        NULL, NULL, &time_value);
    if (retVal > 0) {
        const long received = recv(self.client_socket, outBuffer, dataLength, 0);
        if (received < 0) {
            _lastError = NEW_ERROR(errno, strerror(errno));
        }
        return received;
    }
    return -1;
}


@end

