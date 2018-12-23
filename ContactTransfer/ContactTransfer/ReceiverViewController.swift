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
    var receiver:TCPReceiveContact?
    override func viewDidLoad() {
        super.viewDidLoad()

        self.receiver = TCPReceiveContact()
        self.receiver?.receiveDelegate = self
        
        // Do any additional setup after loading the view.
    }
    
    
//    func echoService(client: TCPClient) {
//        print("Newclient from:\(client.address)[\(client.port)]")
//        var d = client.read(1024*10)
//        client.send(data: d!)
//        client.close()
//    }
    
    func testServer() {
        let server = TCPServer(address: "192.168.0.101", port: 8444)
        switch server.listen() {
        case .success:
            while true {
                if var client = server.accept() {
                    print("ok")
                    let __data = NSMutableData()
                    while let byt = client.read(1024){
                        let data = NSData.init(bytes: byt, length: byt.count)
                        __data.append(data as Data )
                    }
                    
                    let image = UIImage.init(data: __data as Data)
                    self.receivedImageView.image = image
                } else {
                    print("accept error")
                }
            }
        case .failure(let error):
            print(error)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        testServer()
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
