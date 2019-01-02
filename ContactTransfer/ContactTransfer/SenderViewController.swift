//
//  TransmitterViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 22/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit
import SwiftSocket


class SenderViewController: UIViewController {

    var selectedContacts:[ContactData]!
    var senderInfo:SocketData?
    var sender:TCPContactSend?
    let client = TCPClient(address: "192.168.0.101", port: 8444)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    

    @IBAction func sendData(_ sender: Any) {
        
        
//        if let __data = self.senderInfo {
//            self.sender = TCPContactSend()
//            if let _sender = self.sender {
//                if _sender.initiateConnection(__data.receiverIp, incommingPort: "2442") {
//                    if _sender.isConnected {
//                        print("connected")
//                    }
//
//                }
//            }
//        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
