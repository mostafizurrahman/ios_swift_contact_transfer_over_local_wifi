//
//  SenderBroadcast.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 21/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit

class SenderBroadcast: NSObject {
    typealias SD = SocketData
    var socket_descriptor:Int32 = -1
    override init() {
        super.init()
    }
    
    convenience init(braodcastPort port:Int32) {
        self.init()
        self.socket_descriptor = udpsocket_server("", port)
    }

    func getSocket(FromIP serverIP:String,
                   serverPort port:Int)->Int {
        //create socket
        let socketfd = socket(AF_INET, SOCK_DGRAM, 0);
        var reuse_on = 1
        var ret_opt:Int32 = -1
        let socket_address = UnsafeMutablePointer< sockaddr_in>.allocate(capacity: 1)
        let socklen = MemoryLayout<sockaddr_in>.stride
        socket_address.pointee.sin_family = sa_family_t(AF_INET)
        socket_address.pointee.sin_len = __uint8_t(socklen)
        
        if serverIP.elementsEqual("") ||
            serverIP.elementsEqual("255.255.255.255") {
            ret_opt = setsockopt( socketfd, SOL_SOCKET,
                                      SO_BROADCAST, &reuse_on,
                                      socklen_t(MemoryLayout<Int>.stride) )
            var enable = 1
            if (setsockopt(socketfd, SOL_SOCKET, SO_REUSEADDR, &enable,
                           socklen_t(MemoryLayout<Int>.stride)) < 0) {
                perror("setsockopt(SO_REUSEADDR) failed");
                exit(1)
                //error occured!!!
            }
            socket_address.pointee.sin_port        = in_port_t(port)
            socket_address.pointee.sin_addr.s_addr =  INADDR_ANY
        } else{
                ret_opt = setsockopt( socketfd, SOL_SOCKET, SO_REUSEADDR,
                                      &reuse_on, socklen_t(MemoryLayout<Int>.stride))
                socket_address.pointee.sin_addr.s_addr = inet_addr(serverIP)
                socket_address.pointee.sin_port = in_port_t(port)
//                memset( &serv_addr, '\0', sizeof(serv_addr));
        }
        if ret_opt == -1 {
            return -1
        }
        var addr = withUnsafePointer(to: socket_address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                $0.pointee
            }
        }
        ret_opt = bind(socketfd, &addr, socklen_t(socklen))
        free(socket_address)
        return ret_opt == 0 ? Int(socketfd) : -1
    }
    
    
    func receive(OutData dataPointer:UnsafeMutablePointer<Int8>) -> Int{
        
        let receiver_addr = UnsafeMutablePointer<sockaddr>.allocate(capacity: 1)
        var socket_len = socklen_t(MemoryLayout<sockaddr>.stride)
        memset(receiver_addr, 0x0, Int(socket_len))
        var time_value = timeval()
        time_value.tv_sec = 0
        time_value.tv_usec = 2000
        if setsockopt(Int32(self.socket_descriptor), SOL_SOCKET,
                      SO_RCVTIMEO, &time_value, socket_len) < 0 {
            perror("Socket failed to set options!")
            return -1
        }
        let received_len = recvfrom(Int32(self.socket_descriptor),
                                    dataPointer, SD.DATA_SIZE, 0,
                                    receiver_addr, &socket_len)
        let addr = withUnsafePointer(to: receiver_addr) {
            $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                $0.pointee
            }
        }
        if let cstring_ip = inet_ntoa(addr.sin_addr) {
            let ip_address = String.init(cString: cstring_ip)
            print(ip_address)
        }
        free(receiver_addr)
        if received_len == SD.DATA_SIZE {
            return received_len
        } else if received_len > 0 {
            return 1
        }
//
//            var remoteport:Int32 = 0
//
//        struct sockaddr_in  cli_addr;
//         clilen = sizeof(cli_addr);
//        memset(&cli_addr, 0x0, sizeof(struct sockaddr_in));
//
//        struct timeval tv;
//        tv.tv_sec = 0;
//        tv.tv_usec = 200000;
//        if (setsockopt(socket_fd, SOL_SOCKET, SO_RCVTIMEO,&tv,sizeof(tv)) < 0)
//        {
//            perror("Error");
//        }
//        int len=(int)recvfrom(socket_fd, outdata, expted_len, 0, (struct sockaddr *)&cli_addr, &clilen);
//        char *clientip = inet_ntoa(cli_addr.sin_addr);
//        memcpy(remoteip, clientip, strlen(clientip));
//        *remoteport = cli_addr.sin_port;
//
//
//
//            let readLen:Int32 = swift_udpsocket_recive(fd, buff: buff, len: Int32(expectlen), ip: &remoteipbuff, port: &remoteport)
//            let port:Int = Int(remoteport)
//            var addr:String = ""
//            if let ip = String(CString: remoteipbuff, encoding: NSUTF8StringEncoding)
//            {
//                addr = ip
//            }
//            if readLen <= 0
//            {
//                return (nil, addr, port)
//            }
//            let rs = buff[0...Int(readLen - 1)]
//            let data:[UInt8] = Array(rs)
//            return (data, addr, port)
//        }
//        return (nil, "no ip", 0)
        return -1
    }
}
