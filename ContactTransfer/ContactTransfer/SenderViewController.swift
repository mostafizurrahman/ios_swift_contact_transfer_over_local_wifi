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

    
    typealias SD = SocketData
    var selectedContacts:[ContactData]!
    var receiverArray:[SocketData] = []
    var device_ip_address:String = ""
    var receiveBraodcast = true
    var senderInfo:SocketData?
    
    var sendingContact:TCPContactSend?
    var sendCount:Int = 0
    var recvCount:Int = 0
    var contactDataLen:Int = 0
    var receiverData:SocketData?
    var abortSendingOperation = false
    //receiver button position arrrays
    var hasReceiverArray = [false, false, false, false, false, false]
    var receiverFrameArray:[CGRect] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureReceiverPositions()
        let device_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(device_ip, 0, 16)
        udpsocket_self_ip(device_ip)
        self.device_ip_address = String.init(cString: device_ip)
        free(device_ip)
        self.sendingContact = TCPContactSend()
        self.sendingContact?.sendDelegate = self
        // Do any additional setup after loading the view.
        self.startBroadcastReciever()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.abortSendingOperation = true
        self.receiveBraodcast = false
    }
    
    deinit {
        self.abortSendingOperation = true
        self.receiveBraodcast = false
    }
    
    fileprivate func configureReceiverPositions(){
        
        let dimension:CGFloat = 45
        let __width = UIScreen.main.bounds.width / 6.0
        var origin_y = UIScreen.main.bounds.height * 0.25
        
        let origin_x = __width / 2 - dimension / 2
        var __rect = CGRect(x: origin_x, y: origin_y,
                            width: dimension, height: dimension)
        self.receiverFrameArray.append(__rect)
        __rect = CGRect(x: origin_x + __width, y: origin_y - __width * 0.25,
                        width: dimension, height: dimension)
        self.receiverFrameArray.append(__rect)
        __rect = CGRect(x: origin_x + __width * 2, y: origin_y,
                        width: dimension, height: dimension)
        self.receiverFrameArray.append(__rect)
        origin_y = UIScreen.main.bounds.height * 0.25 + dimension * 1.5
        __rect = CGRect(x: origin_x, y: origin_y,
                            width: dimension, height: dimension)
        self.receiverFrameArray.append(__rect)
        __rect = CGRect(x: origin_x + __width, y: origin_y - __width * 0.25,
                        width: dimension, height: dimension)
        self.receiverFrameArray.append(__rect)
        __rect = CGRect(x: origin_x + __width * 2, y: origin_y,
                        width: dimension, height: dimension)
        self.receiverFrameArray.append(__rect)
    }

    fileprivate func startBroadcastReciever(){
        self.receiveBraodcast = true
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
                        })  {
                            self.receiverArray.append(socketData)
                            self.createReceiverButton(socketData)
                        } else if socketData.commStatus == .offline {
                            self.removeReceiver(socketData)
                        }
                    }
                }
                sleep(1)
            }
        }
    }
    
    fileprivate func createReceiverButton(_ socketData:SocketData) {
        if self.receiveBraodcast {
            if let index = self.hasReceiverArray.firstIndex(of: false) {
                self.hasReceiverArray[index] = true
                let buttonRect = self.receiverFrameArray[index]
                let reciverButton = UIButton(frame: buttonRect)
                reciverButton.addTarget(self, action: #selector(startSendingData(_:)), for: .touchUpInside)
                reciverButton.setTitle("iPhone", for: .normal)
                reciverButton.layer.cornerRadius = buttonRect.width / 2;
                reciverButton.layer.masksToBounds = true
                reciverButton.layer.borderColor = UIColor.gray.cgColor
                reciverButton.layer.borderWidth = 0.75
                reciverButton.restorationIdentifier = socketData.senderIp
                self.view.addSubview(reciverButton)
            }
        }
    }
    
    @objc func startSendingData(_ sender:UIButton){
        
        if let ip_address = sender.restorationIdentifier {
            
            DispatchQueue.global().async {
                self.receiveBraodcast = false
            }
            if let contactData = self.receiverArray.filter ({$0.senderIp.elementsEqual(ip_address)}).first {
                self.receiverData = contactData
                
                //create a random port for TCP connections
                let comm_port = Int.random(in: 9000...9999)
                self.receiverData?.commPort = comm_port
                
                let user_name = UserDefaults.standard.string(forKey: "UserName")
                let parameters:[String : AnyObject] = ["DEVICE_OS" : 2 as AnyObject,
                                                       "DEVICE_MODEL" : UIDevice.modelName as AnyObject,
                                                       "SENDER_IP" : self.device_ip_address as AnyObject ,
                                                       "SENDER_NAME" : user_name as AnyObject,
                                                       "RECEIV_IP" : ip_address as AnyObject,
                                                       "RECEIV_NAME" : "\(self.selectedContacts.count)" as AnyObject,
                                                       "COMM_STATUS" : SOStatus.receive.rawValue as AnyObject,
                                                       "COMM_PORT" : comm_port as AnyObject]
                let socketData = SocketData(dictionary: parameters)
                let braodcastSocket = BroadcastDataSender()
                DispatchQueue.global().async {
                    //sending receiving request...
                    for _ in 0...5{
                        let send_len = braodcastSocket.send(Data: socketData, comPort: SD.DATAREQ_PORT)
                        if send_len > 0 {
                            print("sendiong to \(socketData.receiverIp)")
                        }
                    }
                    for _ in 0...1000 {
                        continue
                    }
                    
                    //MARK: TCP CONTACT SEND
                    
                    if self.inititateConnection() {
                        print("connection___success!!!!___")
                        self.sendContactData()
                    } else {
                        
                    }
                }
            }
        }
    }
    
    func sendContactData(){
        if let __sender = self.sendingContact {
            
            while self.sendCount < self.selectedContacts.count
            && !self.abortSendingOperation {
                let contactData = self.selectedContacts[self.sendCount]
                let raw_data = contactData.getData()
                self.contactDataLen = raw_data.count
                __sender.sendContact(raw_data)
            }
            
            if let enddata = "END".data(using: .utf8) {
                for _ in 0...5 {
                    __sender.sendContact(enddata)
                }
            }
        }
    }
    
    func inititateConnection()->Bool{
        if let __sender = self.sendingContact,
            let socketData = self.self.receiverData {
            
            var is_connected = __sender.initiateConnection(socketData.senderIp,
                                                           incommingPort: "\(socketData.commPort)")
            if !is_connected {
                var index = 0
                while index < 10 && !is_connected {
                    is_connected = __sender.initiateConnection(socketData.senderIp,
                                                               incommingPort: "\(socketData.commPort)")
                    index += 1
                    print("\(socketData.commPort)_\(socketData.senderIp)")
                    sleep(1)
                    if is_connected {
                        print("__SUCCESS_CONNECTED...")
                    } else {
                        print("__failed...")
                    }
                }
            }
            return is_connected
            
        }
        return false
    }
    
    fileprivate func removeReceiver(_ socketData:SocketData){
        
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



extension SenderViewController : TCPSendContactDelegate {
    func onContactSendSuccess(_ length: Int32) {
        print("sending \(self.sendCount)")
        if Int(length) == self.contactDataLen {
            if let __sender = self.sendingContact {
                var statusLen = __sender.receiveStatus()
                var maxTry = 20
                while statusLen == -1 && maxTry > 0 {
                    statusLen = __sender.receiveStatus()
                    maxTry -= 1
                }
                if maxTry == 0 {
                    self.abortSendingOperation = true
                    print("unable to send data... aborting sending operations! receiver unavailable! Thank you good day")
                }
            }
        }
    }
    
    func onContactSendError(_ sendError: Error!) {
        print("error occured")
    }
    
    func onSendStatusReceived(_ count: Int32) {
        print("receiver received contact ___ \(count)")
        self.sendCount = Int(count)
        self.abortSendingOperation = self.sendCount == self.selectedContacts.count
    }
}
