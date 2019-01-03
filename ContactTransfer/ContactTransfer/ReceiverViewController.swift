//
//  ReceiverViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 22/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit
import SwiftSocket

class ReceiverViewController: UIViewController {
    
    @IBOutlet weak var receivedImageView: UIImageView!
    var senderInfo:SocketData?
    var countactCount:Int = 0
    var successCount:Int = 0
    @IBOutlet weak var contactNameLabel: UILabel!
    
    var receiveContact:TCPReceiveContact?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.receiveContact = TCPReceiveContact()
        self.receiveContact?.receiveDelegate = self
        self.contactNameLabel.text = "\(self.senderInfo?.commPort)_\(self.senderInfo?.receiverIp)"
        DispatchQueue.global().async {
            self.initiateConnections()
        }
        // Do any additional setup after loading the view.
    }
    
    fileprivate func initiateConnections(){
        if let contactData = self.senderInfo {
            if let count = Int(contactData.receiverName) {
                self.countactCount =  count
                var is_connected = false
                var index = 0
                while index < 5 && !is_connected {
                    guard let __receiver = self.receiveContact else {
                        continue
                    }
                    is_connected = __receiver.initiateConnection("\(contactData.commPort)", timeOut: 5)
                    index += 1
                    
                }
                if is_connected {
                    guard let __receiver = self.receiveContact else {
                        return
                    }
                    __receiver.receiveContact()
                }
            }
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        if let _data = senderInfo, let _rcv = self.receiver {
//            while !_rcv.initiateConnection("2442", timeOut: 10){
//                print("not connected")
//            }
//            print("connected")
//            _rcv.receiveContact()
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


extension ReceiverViewController:TCPReceiveContactDelegate {
    func onContactReceivedSuccess(_ data: Data!) {
        let contactData = ContactData.init(withData: data)
        DispatchQueue.main.async {
            self.contactNameLabel.text = contactData.contactName_display
        }
        self.countactCount -= 1
        if self.countactCount > 0 {
            
            guard let __receiver = self.receiveContact else {
                return
            }
            self.successCount += 1
            __receiver.sendStatus("\(self.successCount)")
            __receiver.receiveContact()
        }
        
    }
    
    func onContactReceiveError(_ receiveError: Error!) {
        
    }
    
//    func contactReceived(with data: Data!) {
//        if let image = UIImage.init(data: data) {
//            self.receivedImageView.image = image
//        }
//    }
//    
//    func contactReceiveWithError(_ receiveError: Error!) {
//        print(receiveError)
//    }
    
    
}
