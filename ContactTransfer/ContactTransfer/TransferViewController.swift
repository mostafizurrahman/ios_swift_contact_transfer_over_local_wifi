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
import NVActivityIndicatorView
import AVFoundation

class TransferViewController: UIViewController {
    
    typealias SD = SocketData
    @IBOutlet weak var iconImgVIew: UIImageView!
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
    var acitivity:NVActivityIndicatorView?
    @IBOutlet weak var transferView: UIView!
    @IBOutlet weak var trailingSpace: NSLayoutConstraint!
    @IBOutlet weak var leadingSpace: NSLayoutConstraint!
    @IBOutlet weak var pulsView: UIView!
    @IBOutlet weak var broadcastLabel: UILabel!
    @IBOutlet weak var broadcastLayout: NSLayoutConstraint!
    @IBOutlet weak var abortButton: BorderButton!
    
    @IBOutlet weak var buttonSend:UIButton!
    @IBOutlet weak var buttonRecv:UIButton!
    @IBOutlet weak var abortSpace: NSLayoutConstraint!
    
    @IBOutlet weak var erroStatusLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for btn in [self.buttonSend, self.buttonRecv] {
            btn?.layer.cornerRadius = 8
            btn?.layer.borderColor = UIColor.white.cgColor
            btn?.layer.borderWidth = 0.75
        }
        self.iconImgVIew.layer.cornerRadius = self.iconImgVIew.frame.size.width/2
        self.iconImgVIew.layer.masksToBounds = true
        
        self.trailingSpace.constant = -HVC.MSW
        self.view.layoutIfNeeded()
        let client_ip = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
        memset(client_ip, 0, 16)
        udpsocket_self_ip(client_ip)
        self.deviceIPAddress = String.init(cString: client_ip)
        free(client_ip)
        if self.view.bounds.height > self.view.bounds.width {
            self.broadcastLayout.constant = HVC.MSW / 2 - self.broadcastLabel.frame.size.width/2
            self.abortSpace.constant =  HVC.MSW / 2 - self.abortButton.frame.size.width/2
            
        } else {
            self.broadcastLayout.constant = (HVC.MSW / 2 - self.broadcastLabel.frame.size.width/2) / 2
            self.abortSpace.constant = (HVC.MSW / 2 - self.abortButton.frame.size.width/2) / 2
        }
        self.setErrorStatus(HasError:false)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(broadcastOffline),
                                               name: UIApplication.willResignActiveNotification, // UIApplication.didBecomeActiveNotification for swift 4.2+
            object: nil)
        
        let item = UIBarButtonItem.SystemItem.bookmarks
        let editButton   = UIBarButtonItem(barButtonSystemItem: item, target: self,
                                           action: #selector(didTapEditButton(_:)))
        self.navigationItem.rightBarButtonItems = [editButton]
    }
    
    @objc func didTapEditButton(_ sender:UIBarButtonItem){
        guard let url = URL(string: "https://itunes.apple.com/us/developer/mostafizur-rahman/id1386969788?mt=8") else {
            return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    fileprivate func setErrorStatus(HasError err : Bool){
        if err {
            let color = UIColor.init(rgb: 0xFF0066)
            self.erroStatusLabel.text = "❌ Check Wifi, Connection fail!"
            self.erroStatusLabel.textColor = color
        } else {
            let color =  UIColor.init(rgb: 0x3BCB63)
            self.erroStatusLabel.text = "✅ Onile! "
            self.erroStatusLabel.textColor = color
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var __width:CGFloat  = 0.0
        var __height:CGFloat = 0.0
        if UIDevice.current.orientation.isLandscape {
            
            print("Landscape")
            __height = HVC.MSW < HVC.MSH ?  HVC.MSH : HVC.MSW
            __width = HVC.MSW > HVC.MSH ?  HVC.MSH : HVC.MSW
        } else {
            __width = HVC.MSW > HVC.MSH ?  HVC.MSH : HVC.MSW
            __height = HVC.MSW < HVC.MSH ?  HVC.MSH : HVC.MSW
            print("Portrait")
        }
        self.broadcastLayout.constant = __width / 2
            - self.broadcastLabel.frame.size.width / 2
        self.abortSpace.constant =  __width / 2
            - self.abortButton.frame.size.width / 2
        if self.trailingSpace.constant != 0 {
            self.trailingSpace.constant = -__height
            self.view.layoutIfNeeded()
        }
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
            DispatchQueue.main.async {
                self.deviceNameLabel.text = self.deviceName
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
                } else {
                    DispatchQueue.main.async {
                        self.setErrorStatus(HasError:true)
                    }
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
                } else if recv_data == -1000 {
                    DispatchQueue.main.async {
                        self.setErrorStatus(HasError:true)
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
        self.broadcastOffline()
        self.acitivity?.removeFromSuperview()
        self.acitivity?.stopAnimating()
        self.acitivity = nil
        self.broadcastQueue.async {
            self.shouldBroadcastAddress = false
        }
        self.receivingQueue.async {
            self.shouldReceiveDataRequest = false
        }
        self.leadingSpace.constant = 0
        self.trailingSpace.constant = UIDevice.current.orientation.isLandscape ? -HVC.MSH : -HVC.MSW
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (_finished) in
            for pulsator in self.pulsArray {
                pulsator.removeAllAnimations()
                pulsator.removeFromSuperlayer()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Contact Transfer"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = nil
    }
    
    @IBAction func exitDataTransfer(_ sender: Any) {
        self.stopQueue()
        self.title = "Contact Transfer"
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
        self.setErrorStatus(HasError:false)
        self.leadingSpace.constant = -HVC.MSW / 2
        self.trailingSpace.constant = 0
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }) { (_finished) in
            self.title = "Waiting for sender..."
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
        self.acitivity = NVActivityIndicatorView(frame: self.pulsView.bounds,
                                                 type: .lineScale,
                                                 color: UIColor.init(rgb:0xFF7060),
                                                 padding: 0)
        self.acitivity?.startAnimating()
        self.pulsView.addSubview(acitivity!)
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
                
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            completionHandler(false)
        })
        present(alert, animated: true)
    }
    
    @objc func broadcastOffline(){
        let parameters:[String : AnyObject] = ["DEVICE_OS" : 2 as AnyObject,
                                               "DEVICE_MODEL" : UIDevice.modelName as AnyObject,
                                               "SENDER_IP" : self.deviceIPAddress as AnyObject ,
                                               "SENDER_NAME" : self.deviceName as AnyObject,
                                               "RECEIV_IP" : ServerSocket.getBroadcastAddress() as AnyObject,
                                               "RECEIV_NAME" : "BROADCAST" as AnyObject,
                                               "COMM_STATUS" : SOStatus.offline.rawValue as AnyObject,
                                               "COMM_PORT" : SD.BRDCAST_PORT as AnyObject]
        let data = SocketData(dictionary: parameters)
        let braodcastSocket = BroadcastDataSender()
        _ = braodcastSocket.send(Data: data)
        _ = braodcastSocket.send(Data: data)
        _ = braodcastSocket.send(Data: data)
    }
}


