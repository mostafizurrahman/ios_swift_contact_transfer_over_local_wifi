//
//  TransmitterViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 22/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit

import NVActivityIndicatorView
import AVFoundation
import GoogleMobileAds
import StoreKit


class SenderViewController: UIViewController {

    typealias HVC = TransferViewController
    typealias SD = SocketData
    var selectedContacts:[ContactData]!
    var receiverArray:[SocketData] = []
    var device_ip_address:String = ""
    var receiveBraodcast = true
    var senderInfo:SocketData?
    
    
    @IBOutlet var receiverButtonArray: [UIView]!
    var removedIP:[String:Int] = [:]
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var googleBannerView: GADBannerView!
    @IBOutlet weak var satusLabel: UILabel!
    
    
    @IBOutlet weak var animationView: UIView!
    
    
    
    var sendingContact:TCPContactSend?
    var sendCount:Int = 0
    var recvCount:Int = 0
    var contactDataLen:Int = 0
    var receiverData:SocketData?
    var abortSendingOperation = false
    //receiver button position arrrays
    var hasReceiverArray = [false, false, false, false, false, false]
    var activityView:NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let device_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(device_ip, 0, 16)
        udpsocket_self_ip(device_ip)
        self.device_ip_address = String.init(cString: device_ip)
        free(device_ip)
        self.sendingContact = TCPContactSend()
        self.sendingContact?.sendDelegate = self
        self.activityView = NVActivityIndicatorView(frame: self.animationView.bounds,
                                                   type: .ballScaleRippleMultiple,
                                                   color: UIColor.init(rgb: 0xFF6070),
                                                   padding: 0)
        self.animationView.addSubview(activityView)
        activityView.startAnimating()
        // Do any additional setup after loading the view.
        
        self.startBroadcastReciever()
        let item = UIBarButtonItem.SystemItem.bookmarks
        let editButton   = UIBarButtonItem(barButtonSystemItem: item, target: self,
                                           action: #selector(openFaceBook(_:)))
        self.navigationItem.rightBarButtonItems = [editButton]
        guard let nav = (self.navigationController as? AdViewController) else {
            return
        }
        weak var __self = self
        nav.set(BannerAd: self.googleBannerView, withRoot: __self ?? self)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.abortSendingOperation = true
        self.receiveBraodcast = false
    }
    
    deinit {
        if let __itms = self.navigationItem.rightBarButtonItems?.first {
            __itms.target = nil
        }
        self.abortSendingOperation = true
        self.receiveBraodcast = false
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
                        
                        if self.removedIP.keys.contains(socketData.senderIp){
                            if let __count =  self.removedIP[socketData.senderIp] {
                                if __count > 0 {
                                    let value = __count - 1
                                    if value == 0 {
                                        self.removedIP.removeValue(forKey: socketData.senderIp)
                                    } else {
                                        self.removedIP[socketData.senderIp] = value
                                        return
                                    }
                                }
                            }
                        }
                        
                        if !self.receiverArray.contains(where: { (soc_data) -> Bool in
                            return soc_data.senderIp.elementsEqual(socketData.senderIp)
                        })  {
                            self.receiverArray.append(socketData)
                            self.createReceiverButton(socketData)
                        DispatchQueue.main.async {
                            self.statusLabel.textColor = UIColor.init(rgb: 0x3BCB63)
                            self.statusLabel.text = "New Receiver : \(socketData.senderName)"
                        }
                        } else if socketData.commStatus == .offline {
                            self.removeReceiver(socketData)
                        }
                    }
                }
                sleep(1)
            }
            free(dataPointer)
        }
    }
    
    fileprivate func createReceiverButton(_ socketData:SocketData) {
        if self.receiveBraodcast {
            if let index = self.hasReceiverArray.firstIndex(of: false) {
                self.hasReceiverArray[index] = true
                let buttonView = self.receiverButtonArray[index]
                buttonView.isHidden = false
                if let __button = buttonView.viewWithTag(1212) as? UIButton {
                    if socketData.deviceOSType == .iOS {
                        let image = UIImage.init(named: "apple_def")
                        __button.setBackgroundImage(image, for: .normal)
                        
                        let himage = UIImage.init(named: "apple_h")
                        __button.setBackgroundImage(himage, for: .highlighted)
                    } else if socketData.deviceOSType == .android {
                        __button.setImage(UIImage(named: "android_def"), for: .normal)
                        __button.setImage(UIImage(named: "android_h"), for: .highlighted)
                    }
                    __button.restorationIdentifier = socketData.senderIp
                }
                if let __titleLabel = buttonView.viewWithTag(1313) as? UILabel {
                    let name = socketData.senderName
                    __titleLabel.text = name
                }
            }
        }
    }
    
    @IBAction func selectReceiver(_ sender: UIButton) {
        
        self.startSendingData(sender)
    }
    
    
    @objc func startSendingData(_ sender:UIButton){
        
        if let ip_address = sender.restorationIdentifier {
            
            DispatchQueue.global().async {
                self.receiveBraodcast = false
                DispatchQueue.main.async {
                    for view in self.receiverButtonArray {
                        view.isHidden = true
                    }
                    self.statusLabel.text = ""
                    self.satusLabel.text = "Archiving data...."
                    self.satusLabel.textColor = .black
                }
            }
            if let contactData = self.receiverArray.filter ({$0.senderIp.elementsEqual(ip_address)}).first {
                self.receiverData = contactData
                
                //create a random port for TCP connections
                let comm_port = Int.random(in: 9000...9999)
                self.receiverData?.commPort = comm_port
                
                let archived_data = self.getData()
                let user_name = UserDefaults.standard.string(forKey: "UserName")
                let parameters:[String : AnyObject] = ["DEVICE_OS" : OSType.iOS as AnyObject,
                                                       "DEVICE_MODEL" : UIDevice.modelName as AnyObject,
                                                       "SENDER_IP" : self.device_ip_address as AnyObject ,
                                                       "SENDER_NAME" : user_name as AnyObject,
                                                       "RECEIV_IP" : ip_address as AnyObject,
                                                       "RECEIV_NAME" : "\(archived_data.count)" as AnyObject, //this line should be replaced whith proper data model
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
                        
                        if let __sender = self.sendingContact {
                            DispatchQueue.main.async {
                                self.satusLabel.text = "Sending data...."
                            }
                            __sender.sendContact(archived_data)
                        }
                    } else {
                        
                    }
                }
            }
        }
    }
    
    func getData()->Data{
            var image_data = Data()
            var contactString = "{"
            for contactData in self.selectedContacts {
                let contact_str = contactData.toJson()
                contactString.append(String(contact_str.dropLast().dropFirst()))
                contactString.append(",")
                
                if let imageData = contactData.contactImageData {
                    guard let identifierData = contactData.identifier.data(using: .utf8) else {
                        continue
                    }
                    guard let idfdCount = "\(identifierData.count)".data(using: .utf8) else {
                        continue
                    }
                    let countString = "\(imageData.count)"
                    guard let imageDataCount = countString.data(using: .utf8) else {
                        continue
                    }
                    let strCount = "\(imageDataCount.count)"
                    let counting =  strCount.count < 2 ?
                    "0\(strCount)" : strCount
                    guard let countData = counting.data(using: .utf8) else {
                        continue
                    }
                    image_data.append(idfdCount)//2 len
                    image_data.append(identifierData)//36 len
                    image_data.append(countData) //2 len
                    image_data.append(imageDataCount)//24 len
                    image_data.append(imageData)
                }
            }
            contactString = String(contactString.dropLast())
            contactString.append("}")
            if let __data = contactString.data(using: .utf8) {
                var send_data = Data()
                if let countData = "\(__data.count)".data(using: .utf8) {
                    print(countData.count)
                    var countString = "\(countData.count)"
                    if countString.count < 2 {
                        countString = "0\(countData.count)"
                    }
                    if let subCount = countString.data(using: .utf8) {
                        send_data.append(subCount)
                        send_data.append(countData)
                        send_data.append(__data)
                        send_data.append(image_data)
                    }
                }
                return send_data//837300
            }
        return Data()
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
        
        DispatchQueue.main.async {
            for view in self.receiverButtonArray {
                guard let __button = view.viewWithTag(1212) as? UIButton ,
                let name = (view.viewWithTag(1313) as? UILabel)?.text else {
                    continue
                }
                self.statusLabel.textColor = .red
                self.statusLabel.text = "\(name) is removed!"
                if let idf = __button.restorationIdentifier {
                    if idf.contains(socketData.senderIp) {
                        view.isHidden = true
                        __button.restorationIdentifier = nil
                        if let __index = self.receiverButtonArray.firstIndex(of: view) {
                            self.hasReceiverArray[__index] = false
                        }
                        DispatchQueue.global().async {
                            self.removedIP[idf] = 5
                            self.receiverArray = self.receiverArray.filter ({!$0.senderIp.elementsEqual(idf)})
                            
                        }
                        break
                    }
                }
            }
        }
        
    }
    
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @objc func openFaceBook(_ sender: Any) {
        guard  let imageUrl = URL(string: "https://www.facebook.com/imagebucket.hashtag/") else {
            return
        }
        if UIApplication.shared.canOpenURL(imageUrl) {
            UIApplication.shared.openURL(imageUrl)
        }
    }
}



extension SenderViewController : TCPSendContactDelegate {
    func onContactSendSuccess(_ length: UInt) { 
        print("sending \(self.sendCount)")
        DispatchQueue.main.async {
            self.satusLabel.text = "Suceessfully sent all contacts!"
            self.statusLabel.text = "Please! Exit to initiate new transfer..."
            if let __nav = self.navigationController as? AdViewController {
                __nav.showInterstitial()
            }
        }
        
//        if Int(length) == self.contactDataLen {
//            if let __sender = self.sendingContact {
//                var statusLen = __sender.receiveStatus()
//                var maxTry = 20
//                while statusLen == -1 && maxTry > 0 {
//                    statusLen = __sender.receiveStatus()
//                    maxTry -= 1
//                }
//                if maxTry == 0 {
//                    self.abortSendingOperation = true
//                    print("unable to send data... aborting sending operations! receiver unavailable! Thank you good day")
//                }
//            }
//        }
    }
    
    func onContactSendError(_ sendError: Error!) {
        print("error : \(sendError)")
        self.abortSendingOperation = true
        DispatchQueue.main.async {
            self.statusLabel.textColor = UIColor.init(rgb: 0xFF0066)
            self.satusLabel.text = "❌ Error Sending..."
            self.statusLabel.text = "Receiver unavailable!\nAborted"
            
            let alert = UIAlertController.init(title: "Receiver Unavailable!",
                                   message: "Receiver fail to receive contacts! Either receiver is inactive or connection fails.",
                                   preferredStyle: .actionSheet)
            let action = UIAlertAction.init(title: "Dismiss",
                                            style: UIAlertAction.Style.default,
                                            handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            if let __nav = self.navigationController as? AdViewController {
                __nav.showInterstitial()
            }
        }
    }
    
    func onSendStatusReceived(_ count: Int32) {
        print("receiver received contact ___ \(count)")
        self.sendCount = Int(count)
        self.abortSendingOperation = self.sendCount == self.selectedContacts.count
        DispatchQueue.main.async {
            self.satusLabel.text = "✅ Successfully sent \(self.sendCount) of \(self.selectedContacts.count) contacts."
    
        }
        
        if self.abortSendingOperation  {
            self.playNotification(name:"notification_finished")
            
        }
    }
}
