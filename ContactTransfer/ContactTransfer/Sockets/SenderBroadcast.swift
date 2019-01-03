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

    deinit {
        print("deinit called")
        udpsocket_close(self.socket_descriptor)
    }
    
    func receive(OutData dataPointer:UnsafeMutablePointer<Int8>) -> Int{
        let remote_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        let remote_port = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let received_len = udpsocket_receive(self.socket_descriptor,
                                             dataPointer, Int32(SD.DATA_SIZE),
                                             remote_ip, remote_port)
        if received_len > 0 {
            let str_ip = String.init(cString: remote_ip)
            let int_port = remote_port.pointee
            print("sever ip = \(str_ip) __ server port = \(int_port)")
            
        } else {
            print("no data found yet!!!")
        }
        free(remote_port)
        free(remote_ip)
        return Int(received_len)
    }
}
