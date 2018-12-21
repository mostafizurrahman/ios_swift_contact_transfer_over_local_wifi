//
//  ReceiverBroadcast.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 21/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//


import Foundation
//Receiver will receive data, it will broadcast along his IP to the data sender
//Receiver will send broadcast data
class ReceiverBroadcast {

    typealias SD = SocketData
    static let BROAD_CAST_IP = "255.255.255.255"
    
    
    var remote_address:String = ""
    var remote_port:Int = -1
    var device_address:String = ""
    var socket_descriptor:Int32 = -1
    
    public init(self_address ip_address:String, broadcast_port port:Int)  {
        
        let remote_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(remote_ip, 0, 16)
        let status = self.getServerIPAddress(self_address: ip_address,
                                          remote_address: remote_ip)
        if status == 0 {
            self.remote_address = String.init(cString: remote_ip)
            self.remote_port = port
            self.socket_descriptor = self.getUDPClient()
            self.device_address = ReceiverBroadcast.getIPAddress() ?? ""
            
        }
    }
    
    func send(Data socketData:SocketData) -> Int {
        var socket_address = UnsafeMutablePointer< sockaddr_in>.allocate(capacity: 1)
        let socklen = MemoryLayout<sockaddr_in>.stride
        memset(&socket_address, 0x0, socklen)
        socket_address.pointee.sin_family = sa_family_t(AF_INET)
        socket_address.pointee.sin_port = in_port_t(socketData.commPort)
        socket_address.pointee.sin_addr.s_addr = inet_addr(socketData.receiverIp)
        let raw_data = UnsafeMutablePointer<Int8>.allocate(capacity: SD.DATA_SIZE)
        
        
        var addr = withUnsafePointer(to: socket_address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                $0.pointee
            }
        }
        
        socketData.set(Data: raw_data)
        let send_len = sendto(self.socket_descriptor, raw_data,
                              SD.DATA_SIZE, 0, &addr, socklen_t(socklen))
        free(socket_address)
        free(raw_data)
        return send_len
    }
    
    func getServerIPAddress(self_address host:String,
                            remote_address remote_ip:UnsafeMutablePointer<Int8>)->Int8 {
   
        if let host_ent = gethostbyname(host) {
            let address = UnsafeMutablePointer<sockaddr_in>.allocate(capacity: 1)
            bcopy(host_ent.pointee.h_addr_list,
                  &address.pointee.sin_addr,
                  Int(host_ent.pointee.h_length))
            let client_ip_addr = inet_ntoa(address.pointee.sin_addr)
            memcpy(remote_ip, client_ip_addr, strlen(client_ip_addr))
            freehostent(host_ent)
            free(address)
            return 0
        }
        return -1
    }
    
    func getUDPClient()->Int32 {
    //create socket
        let socket_fd = socket(AF_INET, SOCK_DGRAM, 0)
        var reuse_on = 1
        setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR,
                   &reuse_on, socklen_t(MemoryLayout<Int>.stride))
        setsockopt(socket_fd, SOL_SOCKET, SO_BROADCAST,
                   &reuse_on, socklen_t(MemoryLayout<Int>.stride))
        
        return socket_fd
    }
    
    static func getIPAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    
    
}
