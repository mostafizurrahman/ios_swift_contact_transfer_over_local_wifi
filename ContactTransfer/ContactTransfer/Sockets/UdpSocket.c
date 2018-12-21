//
//  UdpSocket.c
//  Contact Search
//
//  Created by Mostafizur Rahman on 4/16/16.
//  Copyright © 2016 Dotsoft.inc.. All rights reserved.
//


#include "UdpSocket.h"

#define udpsocket_buff_len 8192

#pragma -mark udp connection RETURN SOCKET FD SERVER SIDE
int udpsocket_server(const char *addr, int port) {
    //create socket
    int socketfd = socket(AF_INET, SOCK_DGRAM, 0);
    int reuseon = 1;
    int r = -1;
    
    //bind
    struct sockaddr_in serv_addr;
    serv_addr.sin_len    = sizeof(struct sockaddr_in);
    serv_addr.sin_family = AF_INET;
    
    if(addr == NULL || strlen(addr) == 0 || strcmp(addr, "255.255.255.255") == 0) {
        r = setsockopt( socketfd, SOL_SOCKET, SO_BROADCAST, &reuseon, sizeof(reuseon) );
        int enable = 1;
        if (setsockopt(socketfd, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0)
            perror("setsockopt(SO_REUSEADDR) failed");
        serv_addr.sin_port        = htons(port);
        serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    } else {
        r = setsockopt( socketfd, SOL_SOCKET, SO_REUSEADDR, &reuseon, sizeof(reuseon) );
        serv_addr.sin_addr.s_addr = inet_addr(addr);
        serv_addr.sin_port = htons(port);
        memset( &serv_addr, '\0', sizeof(serv_addr));
    }
    
    if(r == -1) {
        return -1;
    }
    r = bind(socketfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));
    return  r == 0 ? socketfd : -1;
}

#pragma -mark udp SEND

int udpsocket_sentto(int socket_fd,char *msg,int len, char *toaddr, int topotr) {
    struct sockaddr_in addr;
    socklen_t addrlen = sizeof(addr);
    memset(&addr, 0x0, sizeof(struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(topotr);
    addr.sin_addr.s_addr = inet_addr(toaddr);
    int sendlen = (int)sendto(socket_fd, msg, len, 0, (struct sockaddr *)&addr, addrlen);
    return sendlen;
}

#pragma -mark udp RECEIVE
int udpsocket_recive(int socket_fd, char *outdata, int expted_len,
                     char *remoteip, int* remoteport) {
    struct sockaddr_in  cli_addr;
    socklen_t clilen = sizeof(cli_addr);
    memset(&cli_addr, 0x0, sizeof(struct sockaddr_in));
    
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 200000;
    if (setsockopt(socket_fd, SOL_SOCKET, SO_RCVTIMEO,&tv,sizeof(tv)) < 0)
    {
        perror("Error");
    }
    int len=(int)recvfrom(socket_fd, outdata, expted_len, 0, (struct sockaddr *)&cli_addr, &clilen);    
    char *clientip = inet_ntoa(cli_addr.sin_addr);
    memcpy(remoteip, clientip, strlen(clientip));
    *remoteport = cli_addr.sin_port;
    return len;
}

#pragma -mark udp connection DISCONNECT
int udpsocket_close(int socket_fd) {
    //printf("shuting down %d",shutdown(socket_fd, SHUT_WR));
    return close(socket_fd);
}

#pragma -mark udp connection RETURN SOCKET FD CLIENT SIDE
int udpsocket_client(void) {
    //create socket
    int socketfd = socket(AF_INET, SOCK_DGRAM, 0);
    int reuseon = 1;
    setsockopt( socketfd, SOL_SOCKET, SO_REUSEADDR, &reuseon, sizeof(reuseon) );
    return socketfd;
}

#pragma -mark udp BROADCAST ENABLE
void udpsocket_enable_broadcast(int socket_fd) {
    int reuseon = 1;
    setsockopt( socket_fd, SOL_SOCKET, SO_BROADCAST, &reuseon, sizeof(reuseon) );
}

#pragma -mark udp SERVER IP
int udpsocket_get_server_ip(char *host,char *ip) {
    struct hostent *hp;
    struct sockaddr_in addr;
    hp = gethostbyname(host);
    if(hp == NULL) {
        return -1;
    }
    bcopy((char *)hp->h_addr, (char *)&addr.sin_addr, hp->h_length);
    char *clientip = inet_ntoa(addr.sin_addr);
    memcpy(ip, clientip, strlen(clientip));
    return 0;
}

void udpsocket_self_ip(char *address) {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if(strcmp(temp_addr->ifa_name,"en0") == 0)  {
                    char *ip = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr);
                    memccpy(address, ip, 0, strlen(ip));
                    ip  = NULL;
                    break;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
}
