//
//  ReceiverViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 22/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit
import SwiftSocket
import NVActivityIndicatorView

class ReceiverViewController: UIViewController {
    
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var name:UILabel!
    @IBOutlet weak var mobile:UILabel!
    @IBOutlet weak var email:UILabel!
    @IBOutlet weak var other:UILabel!
    @IBOutlet weak var status:UILabel!
    @IBOutlet weak var progress:UIProgressView!
    @IBOutlet weak var animationView:UIView!
    @IBOutlet weak var errorLabel:UILabel!
    
    var activityView:NVActivityIndicatorView?
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
        self.profile.layer.cornerRadius = self.profile.frame.width / 2
        self.profile.layer.masksToBounds = true
        self.profile.layer.borderColor = UIColor.init(rgb: 0xFF0066).cgColor
        self.profile.layer.borderWidth = 0.75
        self.activityView = NVActivityIndicatorView(frame: self.animationView.bounds, type: .orbit, color: UIColor.init(rgb: 0xFF0066), padding: 0)
        self.animationView.addSubview(self.activityView!)
        self.activityView?.startAnimating()
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
                    DispatchQueue.main.async {
                        self.set(ErrorStatus: nil)
                    }
                    guard let __receiver = self.receiveContact else {
                        return
                    }
                    while !self.abortReceiveOperation {
                        __receiver.receiveContact()
                    }
                } else {
                    
                    DispatchQueue.main.async {
                        self.set(ErrorStatus: "Sender Unreachable...")
                    }
                }
                
            }
        }
    }
    
    
    fileprivate func set(ErrorStatus error:String?) {
        if let __err = error{
            self.errorLabel.textColor = UIColor.init(rgb: 0xFF0066)
            self.errorLabel.text = "❌ Network Error! Terminate operation!\n(Details :\(__err))"
        } else {
            self.errorLabel.textColor = UIColor.init(rgb: 0x3BCB63)
            self.errorLabel.text = "✅ Connection live. Contact receive in progress..."
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
        
        
        self.successCount += 1
        
//        Utility.saveContactToAddressBook(receiveContact: contact)
        let status = "\(self.successCount)"
        guard let __receiver = self.receiveContact else {
            self.abortReceiveOperation = true
            return
        }
        __receiver.sendStatus(status)
        
        DispatchQueue.main.async {
            self.name.text = contactData.contactName_display
            self.progress.progress = Float(self.successCount)/Float(self.countactCount)
            self.status.text = "Received \(self.successCount) of \(self.countactCount) contacts."
            if contactData.contactPhoneNumber.count > 0 {
                if let __key_value = contactData.contactPhoneNumber.first {
                    let __key = (__key_value.key).replacingOccurrences(of: "_$!<", with: "")
                    
                    let __number = "\(__key.replacingOccurrences(of: ">!$_", with: "")) : \(__key_value.value as! String)"
                    self.mobile.text = __number
                    
                }
            } else {
                self.mobile.text = "No mobile number found!"
            }
            if contactData.contactEmails.count > 0 {
                if let __key_value = contactData.contactEmails.first {
                    let __key = (__key_value.key).replacingOccurrences(of: "_$!<", with: "")
                    
                    let __number = "\(__key.replacingOccurrences(of: ">!$_", with: "")) : \(__key_value.value as! String)"
                    self.email.text = __number
                }
            } else {
                self.email.text = "No email found!"
            }
            
            if let __country = contactData.contactAddress["country"] as? String {
                let city = contactData.contactAddress["city"] as? String ?? ""
                let street = contactData.contactAddress["street"] as? String ?? ""
                self.other.text = "St : \(street), City : \(city), Country : \(__country)"
            } else if contactData.contactSocials.count  > 0{
                if let social = contactData.contactSocials.first {
                    self.other.text = "\(social.key) : \(social.value)"
                }
            } else {
                self.other.text = ""
            }
            
            if let image_data = contactData.contactImageData {
                let image = UIImage.init(data: image_data)
                self.profile.image = image
            } else {
                self.profile.image = UIImage.init(named: "profile")
            }
        }
        
        if self.successCount == self.countactCount {
            
            print("success received!! all contacts")
            self.abortReceiveOperation = true
            DispatchQueue.main.async {
                self.errorLabel.text = "✅ Received and Saved Contacts..."
                self.activityView?.startAnimating()
                //play TING sound for finished notification
                
            }
        }
        
        
    }
    
    func onContactReceiveError(_ receiveError: Error!) {
        
    }
    
    
}
