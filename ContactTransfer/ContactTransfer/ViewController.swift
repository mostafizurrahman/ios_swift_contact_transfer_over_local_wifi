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
    
    
    var receiverArray = [SocketData]()
    @IBOutlet weak var reveivedLabel: UILabel!
    
    
typealias SD = SocketData
    typealias RB = ReceiverBroadcast
    var broadcastMyIP = true
    var receiveBraodcast = true
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    fileprivate func startBroadCastSender(){
        let broadcastQueue = DispatchQueue(label: "contact.broadcast", attributes: .concurrent)
        let receivingQueue = DispatchQueue(label: "contact.receiving", attributes: .concurrent)
        
        broadcastQueue.async {
            let user_name = UserDefaults.standard.string(forKey: "UserName")
            let parameters:[String : AnyObject] = ["DEVICE_OS" : 2 as AnyObject,
                                                   "DEVICE_MODEL" : UIDevice.modelName as AnyObject,
                                                   "SENDER_IP" : "" as AnyObject ,
                                                   "SENDER_NAME" : user_name as AnyObject,
                                                   "RECEIV_IP" : ServerSocket.getBroadcastAddress() as AnyObject,
                                                   "RECEIV_NAME" : "BROADCAST" as AnyObject,
                                                   "COMM_STATUS" : SOStatus.broadcast.rawValue as AnyObject,
                                                   "COMM_PORT" : SD.BRDCAST_PORT as AnyObject]
            let data = SocketData(dictionary: parameters)
            let braodcastSocket = ReceiverBroadcast(self_address: data.receiverIp,
                                                    broadcast_port: SD.BRDCAST_PORT)
            while self.broadcastMyIP {
                let send_len = braodcastSocket.send(Data: data)
                if send_len > 0 {
                    print(send_len)
                }
                sleep(1)
            }
        }
        
        receivingQueue.async {
            let dataPointer = UnsafeMutablePointer<Int8>.allocate(capacity: SD.DATA_SIZE)
            memset(dataPointer, 0, SD.DATA_SIZE)
            let receiverSocket = SenderBroadcast(braodcastPort: Int32(SD.DATAREQ_PORT))
            while self.receiveBraodcast {
                let recv_data = receiverSocket.receive(OutData:dataPointer)
                if recv_data > 0 {
                    let socketData = SocketData.init()
                    socketData.set(Data: dataPointer)
                    if socketData.commStatus.rawValue.elementsEqual(SOStatus.receive.rawValue) {
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "ReceiveSegue", sender: socketData)
                        }
                        self.broadcastMyIP = false
                        break
                    }
                }
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
                        let socketData = SocketData.init()
                        socketData.set(Data: dataPointer)
                        if !self.receiverArray.contains(where: { (soc_data) -> Bool in
                            return soc_data.senderIp.elementsEqual(socketData.senderIp)
                        }) {
                            self.receiverArray.append(socketData)
                            self.createReceiverButton(socketData)
                        }
                        self.reveivedLabel.text = "received_data \(recv_data)"
                    }
                }
                sleep(1)
            }
        }
    }
    
    fileprivate func createReceiverButton(_ socketData:SocketData) {
        let receiver = UIButton(frame: CGRect(x:30, y:100,width:75,height:75))
        receiver.addTarget(self, action: #selector(startSendingData(_:)), for: .touchUpInside)
        receiver.setTitle("iPhone", for: .normal)
        receiver.layer.cornerRadius = 35;
        receiver.layer.masksToBounds = true
        receiver.layer.borderColor = UIColor.gray.cgColor
        receiver.layer.borderWidth = 0.75
        receiver.restorationIdentifier = socketData.senderIp
        self.view.addSubview(receiver)
    }
    
    @IBAction func sendData(_ sender: Any) {
        self.startBroadcastReciever()
    }
    
    @IBAction func receiveData(_ sender: Any) {
        self.startBroadCastSender()
    }
    
    @objc func startSendingData(_ sender:UIButton){
        if let ip_address = sender.restorationIdentifier {
            let user_name = UserDefaults.standard.string(forKey: "UserName")
            let parameters:[String : AnyObject] = ["DEVICE_OS" : 2 as AnyObject,
                                                   "DEVICE_MODEL" : UIDevice.modelName as AnyObject,
                                                   "SENDER_IP" : "" as AnyObject ,
                                                   "SENDER_NAME" : user_name as AnyObject,
                                                   "RECEIV_IP" : ip_address as AnyObject,
                                                   "RECEIV_NAME" : "RECEIVE" as AnyObject,
                                                   "COMM_STATUS" : SOStatus.receive.rawValue as AnyObject,
                                                   "COMM_PORT" : SD.DATAREQ_PORT as AnyObject]
            let data = SocketData(dictionary: parameters)
            let braodcastSocket = ReceiverBroadcast(self_address: data.receiverIp,
                                                    broadcast_port: SD.DATAREQ_PORT)
            
            for _ in 0...10{
                let send_len = braodcastSocket.send(Data: data)
                if send_len > 0 {
                    print("sendiong to \(data.receiverIp)")
                }
            }
            self.performSegue(withIdentifier: "SenderSegue", sender: data)
        }
    }
    
}

