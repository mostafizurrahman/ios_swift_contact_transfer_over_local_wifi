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
    var abortReceiveOperation = false
    @IBOutlet weak var contactNameLabel: UILabel!
    
    var receiveContact:TCPReceiveContact?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.receiveContact = TCPReceiveContact()
        self.receiveContact?.receiveDelegate = self
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
                    while !self.abortReceiveOperation {
                        __receiver.receiveContact()
                    }
                }
            }
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        let end_data = data.subdata(in: 0...3)
        if let str = String(data: end_data, encoding: .utf8) {
            if str.contains("EN") {
                print("finished contact receiving")
                self.abortReceiveOperation = true
                return
            }
        }
        let contactData = ContactData.init(withData: data)
        DispatchQueue.main.async {
            self.contactNameLabel.text = contactData.contactName_display
        }
        
        
        self.successCount += 1
        
//        Utility.saveContactToAddressBook(receiveContact: contact)
        let status = "\(self.successCount)"
        guard let __receiver = self.receiveContact else {
            self.abortReceiveOperation = true
            return
        }
        __receiver.sendStatus(status)
        print(status)
        if self.successCount == self.countactCount {
            
            print("success received!! all contacts")
            self.abortReceiveOperation = true
        }
        
        
    }
    
    func onContactReceiveError(_ receiveError: Error!) {
        
    }
    
    
}
