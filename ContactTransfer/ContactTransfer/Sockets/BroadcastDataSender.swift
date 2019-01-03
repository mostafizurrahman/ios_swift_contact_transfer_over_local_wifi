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
class BroadcastDataSender {

    typealias SD = SocketData
    var comport:Int? = nil
    var socket_descriptor:Int32 = -1
    
    
    
    public init() {
        self.socket_descriptor = udpsocket_client()
        udpsocket_enable_broadcast(self.socket_descriptor)
    }
    
    
    func send(Data socketData:SocketData) -> Int {
        
        let raw_data = socketData.getData()
        let client_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(client_ip, 0, 16)
        let __data = Array(socketData.receiverIp.utf8)
        memcpy(client_ip, __data, __data.count)
        let comport = self.comport ?? socketData.commPort
        let send_len = udpsocket_sentto(self.socket_descriptor, raw_data,
                                        Int32(SD.DATA_SIZE),
                                        client_ip, Int32(comport))
        if send_len > 0 {
            print("sending success")
        }
        free(client_ip)
        free(raw_data)
        return Int(send_len)
    }
    
    func send(Data socketData:SocketData, comPort port:Int)->Int{
        self.comport = port
        return self.send(Data: socketData)
    }
    deinit {
        print("deinit called")
        udpsocket_close(self.socket_descriptor)
    }
}
