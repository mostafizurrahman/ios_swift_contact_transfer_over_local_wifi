//
//  ReceiverViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 22/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Contacts
import AVFoundation
import GoogleMobileAds
import StoreKit
class ReceiverViewController: UIViewController {
    
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var gogoleBannerView: GADBannerView!
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
    var successCount:UInt = 0
    var abortReceiveOperation = false
    var receivedContacts:[ContactData] = []
    var singleContact = false
    
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
        
        let item = UIBarButtonItem.SystemItem.bookmarks
        let editButton   = UIBarButtonItem(barButtonSystemItem: item, target: self,
                                           action: #selector(openFaceBook(_:)))
        self.navigationItem.rightBarButtonItems = [editButton]
        guard let nav = (self.navigationController as? AdViewController) else {
            return
        }
        weak var __self = self
        nav.set(BannerAd: self.gogoleBannerView, withRoot: __self ?? self)
        // Do any additional setup after loading the view.
    }
    
    
    
    fileprivate func initiateConnections(){
        if let contactData = self.senderInfo {
            if let count = Int(contactData.receiverName)  {
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch_point = touches.first?.location(in: self.view) {
            if self.animationView.frame.contains(touch_point) {
                
                if #available(iOS 10.3, *) {
                    SKStoreReviewController.requestReview()
                } else {
                    // Fallback on earlier versions
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
            self.errorLabel.text = "✅ Contact receive in progress..."
        }
    }
    
    
    @objc func openFaceBook(_ sender: Any) {
        guard  let imageUrl = URL(string: "https://www.facebook.com/imagebucket.hashtag/") else {
            return
        }
        if UIApplication.shared.canOpenURL(imageUrl) {
            UIApplication.shared.openURL(imageUrl)
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
    
    
    var audioPlayer:AVAudioPlayer!
    func playNotification(name fileName:String){
        guard let alertSound = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {return}
        
        do {
            //                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            audioPlayer = try AVAudioPlayer(contentsOf: alertSound)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func process(ContacData data:Data){
        
    }
    
    func display(Info contactData:ContactData){
        self.name.text = contactData.contactName_display
//        self.progress.progress = Float(self.successCount)/Float(self.countactCount)
//        self.status.text = "New contact saved..."
        if contactData.contactPhoneNumber.count > 0 {
            if let __key_value = contactData.contactPhoneNumber.first {
                let __number = "\(__key_value.key) : \(__key_value.value as! String)"
                self.mobile.text = __number
                
            }
        } else {
            self.mobile.text = "No mobile number found!"
        }
        if contactData.contactEmails.count > 0 {
            if let __key_value = contactData.contactEmails.first {
                let __number = "\(__key_value.key) : \(__key_value.value as! String)"
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
}

extension ReceiverViewController:AVAudioPlayerDelegate {
    
}
extension ReceiverViewController:TCPReceiveContactDelegate {
    func onContactReceivedSuccess(_ data: Data!) {
        
        NSLog("0")
        self.abortReceiveOperation = true
        receivedContacts.removeAll()
        let lenData = data.subdata(in: 0...1)
        let lenString = String(data: lenData, encoding: .utf8)
        var countContact = 0
        if let __lenStr = lenString,
            let __len = Int(__lenStr) {
            DispatchQueue.main.async {
                self.status.text = "Extracting contacts...\nPlease! Wait."
                self.playNotification(name:"notification_save")
            }
            NSLog("one")
            let contact_data = data.subdata(in: 2...2+__len-1)
            if let len_string = String(data: contact_data, encoding: .utf8),
                let contact_len = Int(len_string){
                let startIndex = __len + 2
                let jsonData = data.subdata(in: startIndex...startIndex+contact_len-1)
                do {
                    if let contactJson = try JSONSerialization.jsonObject(with: jsonData,
                                                                          options: []) as? [String : AnyObject] {
                        NSLog("two")
                        for key in  contactJson.keys {
                            if let __contact = contactJson[key] as? [String:AnyObject] {
                                let contact = ContactData(withJson: __contact)
                                self.receivedContacts.append(contact)
                                if contact.contactHasImage {
                                    self.receivedContacts.append(contact)
                                } else {
                                    countContact += 1
                                    DispatchQueue.main.async {
                                        self.save(Contact: contact)
                                        self.display(Info: contact)
                                    }
                                }
                            }
                        }
                        
                        if countContact == 1 {
                            DispatchQueue.main.async {
                                if let __nav = self.navigationController as? AdViewController {
                                    __nav.showInterstitial()
                                }
                            }
                        }
                        
                        NSLog("three")
                        var nxtIndex = startIndex+contact_len
                        if nxtIndex < data.count-1 {
                            while nxtIndex < data.count - 1{
                                
                                let idf_len_data = data.subdata(in: nxtIndex...nxtIndex+1)
                                
                                guard let idf_str_data = String(data: idf_len_data, encoding: .utf8) else {
                                    break
                                }
                                guard let idf_count = Int(idf_str_data) else  {
                                    break
                                }
                                let idf_data = data.subdata(in: nxtIndex+2...nxtIndex+idf_count+1)
                                guard let idf_string = String(data: idf_data, encoding: .utf8) else {
                                    break
                                }
                                print(idf_string)
                                nxtIndex = nxtIndex+idf_count+2
                                let len1_data = data.subdata(in: nxtIndex...nxtIndex+1)
                                
                                guard let len1_str = String(data: len1_data, encoding: .utf8) else {
                                    break
                                }
                                guard let len1 = Int(len1_str) else {
                                    break
                                }
                                let len2_data = data.subdata(in: nxtIndex+2...nxtIndex+1+len1)
                                guard let len2_str = String(data:len2_data, encoding: .utf8) else {
                                    break
                                }
                                guard let len2 = Int(len2_str) else {
                                    break
                                }
                                let image_data = data.subdata(in: nxtIndex+2+len1...nxtIndex+1+len1+len2)
                                nxtIndex = nxtIndex+2+len1+len2
                                
                                for contact in self.receivedContacts {
                                    if contact.identifier.elementsEqual(idf_string) {
                                        countContact += 1
                                        contact.contactImageData = image_data
                                        DispatchQueue.global().async {
                                            self.save(Contact: contact)
                                            DispatchQueue.main.async {
                                                self.display(Info: contact)
                                            }
                                        }
                                        break
                                    }
                                }
                            }
                            NSLog("Four")
                            DispatchQueue.main.async {
                                self.errorLabel.text = "✅ Done! \(countContact) Contacts added."
                                self.playNotification(name:"notification_save")
                                if let __nav = self.navigationController as? AdViewController {
                                    __nav.showInterstitial()
                                }
                            }
                        }
                        
                    }
                } catch {
                    print(error)
                }
            }
        } else {
            print("LENGTH DATA ERROR")
            return
        }
    }
    
    func onDataCountRead(_ dataCount: UInt) {
        DispatchQueue.main.async {
            self.successCount += dataCount
            self.progress.progress = Float(self.successCount) / Float(self.countactCount)
            let recv = String(format: "%0.2f%", self.progress.progress * 100.0)
            self.status.text = "Data Received \(recv)"
            if recv.elementsEqual("100.00%") {
                self.status.textColor = UIColor.gray
                self.status.text = "100% data received! Processing...."
            }
        }
    }
    
    func onContactReceiveError(_ receiveError: Error!) {
        self.abortReceiveOperation = true
        DispatchQueue.main.async {
            self.status.textColor = UIColor.init(rgb: 0xFF0066)
            self.status.text = "❌ Sender stops sending contacts...\nAborting!"
            
            let alert = UIAlertController.init(title: "Sender Unavailable!",
                                               message: "Sender fail to send contacts! Either sender is inactive or connection fails.",
                                               preferredStyle: .actionSheet)
            let action = UIAlertAction.init(title: "Dismiss",
                                            style: UIAlertAction.Style.default,
                                            handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    func save(Contact contact:ContactData){
        let contact_store = CNContactStore()
        let saveRequest = CNSaveRequest()
        let cncontact = contact.toContact()
        saveRequest.add(cncontact, toContainerWithIdentifier: nil)
        do {
            try contact_store.execute(saveRequest)
            DispatchQueue.main.async {
//                self.lab
                self.playNotification(name:"notification_finished")
                self.errorLabel.text = "✅ Done! Contact added."
                self.status.text = "Saved contact."
               
            }
        } catch {
            print("i dunno")
        }
    }
}
