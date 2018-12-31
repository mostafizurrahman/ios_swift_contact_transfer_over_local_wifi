//
//  ViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 20/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit
import Pulsator

class ViewController: UIViewController {
    
    @IBOutlet weak var transferView: UIView!
    typealias HVC = ViewController
    @IBOutlet weak var receivedImageView: UIImageView!
    static let MSW = UIScreen.main.bounds.width
    static let MSH = UIScreen.main.bounds.height
    @IBOutlet weak var trailingSpace: NSLayoutConstraint!
    @IBOutlet weak var leadingSpace: NSLayoutConstraint!
    
    let pulsator = Pulsator()
    var deviceName = UIDevice.current.name
    var deviceIPAddress = ""
    var receiverArray = [SocketData]()
    @IBOutlet weak var reveivedLabel: UILabel!
    @IBOutlet weak var pulsView: UIView!
    var receiveContact:TCPReceiveContact?
    var sendingContact:TCPContactSend?
    
    typealias SD = SocketData
    typealias RB = ReceiverBroadcast
    var broadcastMyIP = true
    var receiveBraodcast = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.receiveContact = TCPReceiveContact()
        self.sendingContact = TCPContactSend()
        self.receiveContact?.receiveDelegate = self
        self.sendingContact?.sendDelegate = self
        self.trailingSpace.constant = -HVC.MSW
        self.view.layoutIfNeeded()
        let client_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(client_ip, 0, 16)
        udpsocket_self_ip(client_ip)
        self.deviceIPAddress = String.init(cString: client_ip)
        free(client_ip)
    }
    
    fileprivate func startBroadCastSender(){
        let broadcastQueue = DispatchQueue(label: "contact.broadcast", attributes: .concurrent)
        let receivingQueue = DispatchQueue(label: "contact.receiving", attributes: .concurrent)
        
        broadcastQueue.async {
            if let user_name = UserDefaults.standard.string(forKey: "UserName") {
                self.deviceName = user_name
            }
            let parameters:[String : AnyObject] = ["DEVICE_OS" : 2 as AnyObject,
                                                   "DEVICE_MODEL" : UIDevice.modelName as AnyObject,
                                                   "SENDER_IP" : self.deviceIPAddress as AnyObject ,
                                                   "SENDER_NAME" : self.deviceName as AnyObject,
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
                        self.broadcastMyIP = false
                        self.receiveBraodcast = false
                        var is_connected = false
                        var index = 0
                        while index < 5 && !is_connected {
                            index += 1
                            guard let __receiver = self.receiveContact else {
                                continue
                            }
                            is_connected = __receiver.initiateConnection("3333", timeOut: 15)
                            
                        }
                        if is_connected {
                            guard let __receiver = self.receiveContact else {
                                return
                            }
                            __receiver.receiveContact()
                        }
                        break
                    }
                }
                
                sleep(1)
            }
        }
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
                        }) && !socketData.senderIp.elementsEqual(self.deviceIPAddress) {
                            self.receiverArray.append(socketData)
                            self.createReceiverButton(socketData)
                        }
                        //                        self.reveivedLabel.text = "received_data \(recv_data)"
                    }
                }
                
                sleep(1)
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global().async {
            self.receiveBraodcast = false
            self.broadcastMyIP = false
        }
    }
    @IBAction func exitDataTransfer(_ sender: Any) {
        
        DispatchQueue.global().async {
            self.receiveBraodcast = false
            self.broadcastMyIP = false
        }
        self.leadingSpace.constant = 0
        self.trailingSpace.constant = -HVC.MSW
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }) { (_finished) in
            self.pulsator.removeAllAnimations()
            self.pulsator.removeFromSuperlayer()
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
        self.transferView.addSubview(receiver)
    }
    
    @IBAction func sendData(_ sender: Any) {
        self.startBroadcastReciever()
        self.leadingSpace.constant = -HVC.MSW / 4
        self.trailingSpace.constant = 0
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }) { (_finished) in
            self.startPulse()
        }
    }
    
    @IBAction func receiveData(_ sender: Any) {
        self.startBroadCastSender()
        self.leadingSpace.constant = -HVC.MSW / 4
        self.trailingSpace.constant = 0
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            
        }) { (_finished) in
            self.startPulse()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let idf = segue.identifier {
//            if idf.elementsEqual("SenderSegue") {
//                if let _dest = segue.destination as? TransmitterViewController {
//                    _dest.senderInfo = sender as? SocketData
//                }
//            }
//            else if idf.elementsEqual("ReceiveSegue") {
//                if let _dest = segue.destination as? ReceiverViewController {
//                    _dest.senderInfo = sender as? SocketData
//                }
//            }
        }
    }
    
    @objc func startSendingData(_ sender:UIButton){
        DispatchQueue.global().async {
            self.receiveBraodcast = false
        }
        if let ip_address = sender.restorationIdentifier {
            if let _ = self.receiverArray.filter ({$0.senderIp.elementsEqual(ip_address)}).first {
                let user_name = UserDefaults.standard.string(forKey: "UserName")
                let parameters:[String : AnyObject] = ["DEVICE_OS" : 2 as AnyObject,
                                                       "DEVICE_MODEL" : UIDevice.modelName as AnyObject,
                                                       "SENDER_IP" : self.deviceIPAddress as AnyObject ,
                                                       "SENDER_NAME" : user_name as AnyObject,
                                                       "RECEIV_IP" : ip_address as AnyObject,
                                                       "RECEIV_NAME" : "RECEIVE" as AnyObject,
                                                       "COMM_STATUS" : SOStatus.receive.rawValue as AnyObject,
                                                       "COMM_PORT" : SD.DATAREQ_PORT as AnyObject]
                let data = SocketData(dictionary: parameters)
                let braodcastSocket = ReceiverBroadcast(self_address: data.receiverIp,
                                                        broadcast_port: SD.DATAREQ_PORT)
                
                for _ in 0...3{
                    let send_len = braodcastSocket.send(Data: data)
                    if send_len > 0 {
                        print("sendiong to \(data.receiverIp)")
                    }
                }
                print("ip is")
                print(ip_address)
                if let __sender = self.sendingContact {
                    
                    var is_connected = __sender.initiateConnection(ip_address, incommingPort: "3333")
                    if !is_connected {
                       var index = 0
                        while index < 5 && !is_connected {
                            is_connected = __sender.initiateConnection(ip_address, incommingPort: "3333")
                            index += 1
                        }
                    }
                    
                    if is_connected {
                        if let path = Bundle.main.path(forResource: "IMG_6709", ofType: "jpeg") {
                            do {
                                let raw_data = try Data.init(contentsOf: URL(fileURLWithPath: path))
                                __sender.sendContact(raw_data)
                            }
                            catch {
                                print(error)
                            }
                        }
                    } else {
                        print("holy shits")
                    }
                }
//                self.performSegue(withIdentifier: "SenderSegue", sender: data)
            }
        }
    }
    func startPulse(){
        pulsator.backgroundColor = UIColor.init(rgb: 0xFF0066).cgColor
        self.pulsator.radius = self.pulsView.frame.size.width / 2
        pulsator.position = CGPoint(x: self.pulsView.bounds.midX,
                                    y: self.pulsView.bounds.midY)
        self.pulsView.layer.addSublayer(pulsator)
        pulsator.start()
    }
    
}

extension ViewController:TCPReceiveContactDelegate{
    func onContactReceivedSuccess(_ data: Data!) {
        DispatchQueue.main.async {
            
            self.receivedImageView.isHidden = false
            let image = UIImage.init(data: data)
            self.receivedImageView.image = image
        }
        
    }
    
    func onContactReceiveError(_ receiveError: Error!) {
        
    }
    

}

extension ViewController : TCPSendContactDelegate {
    func onContactSendSuccess(_ length: Int32) {
        
    }
    
    func onContactSendError(_ sendError: Error!) {
    
    }
    
    func onSendStatusReceived(_ count: Int32) {
        
    }
    
    
}
