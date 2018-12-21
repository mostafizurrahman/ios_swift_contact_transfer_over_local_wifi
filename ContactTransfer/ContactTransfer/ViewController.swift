//
//  ViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 20/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var reveivedLabel: UILabel!
    
    
typealias SD = SocketData
    typealias RB = ReceiverBroadcast
    var broadcastMyIP = true
    var receiveBraodcast = true
    override func viewDidLoad() {
        super.viewDidLoad()
//        Broadcast
        // Do any additional setup after loading the view, typically from a nib.
        
        
        
        
//        let dataFormat = CSDataFormatter(sip: deviceIP, rip: BROADCAST_ADDR, rname: "ALL",
//                                         sname: UIDevice.currentDevice().name, status:STATUS_ONLINE, port: RANDOM_TCP_PORT)
        
        
        
    }
    
    
    fileprivate func startBroadCastSender(){
        DispatchQueue.global().async {
            
            let user_name = UserDefaults.standard.string(forKey: "UserName")
            let parameters:[String : AnyObject] = ["DEVICE_OS" : 2 as AnyObject,
                                                   "DEVICE_MODEL" : UIDevice.modelName as AnyObject,
                                                   "SENDER_IP" : "" as AnyObject ,
                                                   "SENDER_NAME" : user_name as AnyObject,
                                                   "RECEIV_IP" : ServerSocket.getBroadcastAddress() as AnyObject,
                                                   "RECEIV_NAME" : "BRAODCAST" as AnyObject,
                                                   "COMM_STATUS" : SOStatus.broadcast.rawValue as AnyObject,
                                                   "COMM_PORT" : SD.BRDCAST_PORT as AnyObject]
            let data = SocketData(dictionary: parameters)
            let braodcastSocket = ReceiverBroadcast(self_address: data.receiverIp,
                                                    broadcast_port: SD.BRDCAST_PORT)
            while self.broadcastMyIP {
                let send_len = braodcastSocket.send(Data: data)
//                print(send_len)
                sleep(1)
            }
        }
    }
    
    fileprivate func startBroadcastReciever(){
        DispatchQueue.global().async {
            let dataPointer = UnsafeMutablePointer<Int8>.allocate(capacity: SD.DATA_SIZE)
            memset(dataPointer, 0, SD.DATA_SIZE)
            let receiverSocket = SenderBroadcast(braodcastPort: Int32(SD.BRDCAST_PORT))
            while self.receiveBraodcast {
                let recv_data = receiverSocket.receive(OutData:dataPointer)
                if recv_data > 0 {
                    DispatchQueue.main.async {
                        self.reveivedLabel.text = "received_data \(recv_data)"
                    }
                }
                sleep(1)
            }
        }
    }
    @IBAction func sendData(_ sender: Any) {
        self.startBroadCastSender()
        
    }
    @IBAction func receiveData(_ sender: Any) {
        self.startBroadcastReciever()
    }
    
}

