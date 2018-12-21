//
//  UdpSocket.h
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 21/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

#ifndef UdpSocket_h
#define UdpSocket_h
#include <stdio.h>
#include <stdlib.h>
#import <ifaddrs.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
int udpsocket_server(const char *, int);
int udpsocket_sentto(int,char *, int,
                     char *, int);
int udpsocket_receive(int, char *, int,
                     char *, int *);
int udpsocket_close(int);
int udpsocket_client(void);
void udpsocket_enable_broadcast(int);
int udpsocket_get_server_ip(char *,char *);
void udpsocket_self_ip(char *);
#endif /* UdpSocket_h */
