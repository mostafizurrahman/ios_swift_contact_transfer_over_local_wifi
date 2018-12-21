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
        
        let client_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(client_ip, 0, 16)
        let __data = Array(ip_address.utf8)
        memcpy(client_ip, __data, __data.count)
        
        self.remote_address = ServerSocket.getBroadcastAddress()
        self.remote_port = port
        self.socket_descriptor = udpsocket_client()
        udpsocket_enable_broadcast(self.socket_descriptor)
        memset(client_ip, 0, 16)
        udpsocket_self_ip(client_ip)
        self.device_address = String.init(cString: client_ip)
        free(client_ip)
    }
    
    func send(Data socketData:SocketData) -> Int {
        socketData.senderIp = self.device_address
        let raw_data = socketData.getData()
        let client_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(client_ip, 0, 16)
        let __data = Array(self.remote_address.utf8)
        memcpy(client_ip, __data, __data.count)
        let send_len = udpsocket_sentto(self.socket_descriptor, raw_data,
                                        Int32(SD.DATA_SIZE), client_ip, Int32(socketData.commPort))
        if send_len > 0 {
            print("sending success")
        }
        free(client_ip)
            
        free(raw_data)
        return Int(send_len)
    }
    
}
