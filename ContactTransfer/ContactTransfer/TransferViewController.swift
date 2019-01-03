//
//  ViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 20/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit
import Pulsator
import Contacts

class TransferViewController: UIViewController {
    
    typealias SD = SocketData
    typealias HVC = TransferViewController
    static let MSW = UIScreen.main.bounds.width
    static let MSH = UIScreen.main.bounds.height
    
    let broadcastQueue = DispatchQueue(label: "contact.broadcast", attributes: .concurrent)
    let receivingQueue = DispatchQueue(label: "contact.receiving", attributes: .concurrent)
    
    var pulsArray:[Pulsator] = []
    var deviceName = UIDevice.current.name
    var deviceIPAddress = ""
    
    var shouldBroadcastAddress = true
    var shouldReceiveDataRequest = true
    
    @IBOutlet weak var transferView: UIView!
    @IBOutlet weak var trailingSpace: NSLayoutConstraint!
    @IBOutlet weak var leadingSpace: NSLayoutConstraint!
    @IBOutlet weak var pulsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.trailingSpace.constant = -HVC.MSW
        self.view.layoutIfNeeded()
        let client_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(client_ip, 0, 16)
        udpsocket_self_ip(client_ip)
        self.deviceIPAddress = String.init(cString: client_ip)
        free(client_ip)
    }
    
    
    fileprivate func startBroadCastSender(){
        self.shouldBroadcastAddress = true
        self.shouldReceiveDataRequest = true
        
        self.broadcastQueue.async {
            if let user_name = UserDefaults.standard.string(forKey: "UserName") {
                self.deviceName = user_name
            } else {
                UserDefaults.standard.set(self.deviceName, forKey: "UserName")
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
            let braodcastSocket = BroadcastDataSender()
            while self.shouldBroadcastAddress {
                let send_len = braodcastSocket.send(Data: data)
                if send_len > 0 {
                    print(send_len)
                }
                sleep(1)
            }
        }
        
        self.receivingQueue.async {
            let dataPointer = UnsafeMutablePointer<Int8>.allocate(capacity: SD.DATA_SIZE)
            memset(dataPointer, 0, SD.DATA_SIZE)
            let receiverSocket = SenderBroadcast(braodcastPort: Int32(SD.DATAREQ_PORT))
            var deallocated = false
            while self.shouldReceiveDataRequest {
                let recv_data = receiverSocket.receive(OutData:dataPointer)
                if recv_data > 0 {
                    let socketData = SocketData.init()
                    socketData.set(Data: dataPointer)
                    free(dataPointer)
                    deallocated = true
                    if socketData.commStatus.rawValue.elementsEqual(SOStatus.receive.rawValue) {
                        
                        DispatchQueue.main.async {
                            self.stopQueue()
                            self.performSegue(withIdentifier: "ReceiveSegue", sender: socketData)
                        }
                        break
                    }
                }
                sleep(1)
            }
            if !deallocated {
                free(dataPointer)
            }
        }
    }
    
    fileprivate func stopQueue(){
        self.broadcastQueue.async {
            self.shouldBroadcastAddress = false
        }
        self.receivingQueue.async {
            self.shouldReceiveDataRequest = false
        }
        self.leadingSpace.constant = 0
        self.trailingSpace.constant = -HVC.MSW
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (_finished) in
            for pulsator in self.pulsArray {
                pulsator.removeAllAnimations()
                pulsator.removeFromSuperlayer()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func exitDataTransfer(_ sender: Any) {
        self.stopQueue()
        
    }
    
    @IBAction func sendData(_ sender: Any) {
        
        self.requestAccess { (granted) in
            if granted {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "ContactSegue", sender: self)
                }
            }
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
            if idf.elementsEqual("ReceiveSegue") {
                if let _dest = segue.destination as? ReceiverViewController {
                    _dest.senderInfo = sender as? SocketData
                }
            }
        }
    }
    
    
    func startPulse(){
        self.pulsArray.removeAll()
//        for i in 0...0 {
            let pulsator = Pulsator()
            let color = UIColor.init(rgb: 0xDFE0D6).withAlphaComponent(CGFloat(0.75 ))
            pulsator.backgroundColor = color.cgColor
            pulsator.radius = self.pulsView.frame.size.width / 2
            pulsator.position = CGPoint(x: self.pulsView.bounds.midX,
                                        y: self.pulsView.bounds.midY)
            self.pulsView.layer.addSublayer(pulsator)
            self.pulsArray.append(pulsator)
            pulsator.start()
//        }
    }
    
    
    func requestAccess(completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            completionHandler(true)
        case .denied:
            showSettingsAlert(completionHandler)
        case .restricted, .notDetermined:
            let store = CNContactStore()
            store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    completionHandler(true)
                } else {
                    DispatchQueue.main.async {
                        self.showSettingsAlert(completionHandler)
                    }
                }
            }
        }
    }
    
    private func showSettingsAlert(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: "This app requires access to Contacts to proceed. Would you like to open settings and grant permission to contacts?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { action in
            completionHandler(false)
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            } else {
                // Fallback on earlier versions
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            completionHandler(false)
        })
        present(alert, animated: true)
    }
    
}

