//
//  SocketData.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 21/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit

enum SOStatus:String {
    case broadcast = "00"
    case receive = "01"
    case send = "10"
    case unknown = "11"
}
enum OSType : Int {
    case unknown=0
    case android
    case iOS
    case tizen
}

class SocketData: NSObject {
    typealias SD = SocketData
    static let BRDCAST_PORT = 8888
    static let DATA_SIZE = 70 // total length of the data
    
    
    static let LOC_DEVICE_OS = 0 //0-1 index // i dont know what is the index, find it later
    static let LOC_DEVICE_MODEL = 1  // 1-3 // name code of the data transfer // idont know exactly
    static let LOC_SENDER_IP = 9 // ip address of the sender
    static let LOC_SENDER_NAME = 21 // name of the sender //20 char long
    static let LOC_RECEIV_IP = 37 // ip of the receiver
    static let LOC_RECEIV_NAME = 49 // name of the receiver//20 char long
    static let LOC_STATUS = 65 // status of the data transfer 2 bytes
    static let LOC_COMPORT = 67//port location in data port is 4 digit long
    
    internal var deviceOSType:OSType = OSType.unknown
    internal var deviceModel:String = ""
    internal var senderIp:String = ""
    internal var senderName:String = ""
    internal var receiverIp:String = ""
    internal var receiverName:String = ""
    internal var commStatus:SOStatus = SOStatus.unknown
    internal var commPort:Int = -1
    
    
    
    
    
//    let dataFormat = CSDataFormatter(sip: deviceIP, rip: BROADCAST_ADDR, rname: "ALL",
//                                     sname: UIDevice.currentDevice().name, status:STATUS_ONLINE, port: RANDOM_TCP_PORT)
    
    
    override init() {
        super.init()
    }
    
    convenience init(dictionary data:[String:AnyObject]) {
        self.init()
        let os_type = Int(data["DEVICE_OS"] as? Int32 ?? 0 )
        self.deviceOSType = OSType.init(rawValue: os_type)!  // must be 4 chaR LONG
        self.deviceModel = data["DEVICE_MODEL"] as? String ?? "UNKNOWN"
        self.senderIp = data["SENDER_IP"] as? String ?? "UNKNOWN"
        self.senderName = data["SENDER_NAME"] as? String ?? "UNKNOWN"
        self.receiverIp = data["RECEIV_IP"] as? String ?? "UNKNOWN"
        self.receiverName = data["RECEIV_NAME"] as? String ?? "UNKNOWN"
        
        
        let value = data["COMM_STATUS"] as? String ?? "11"
        self.commStatus = SOStatus.init(rawValue: (value) ) ?? SOStatus.unknown
        self.commPort = Int(data["COMM_PORT"] as? Int ?? 0 )
    }
    
    fileprivate func get(rawChar pointer:UnsafeMutablePointer<Int8>,
                         start startIndex:Int,
                         end endIndex:Int) -> String {
        
        let data_len = endIndex - startIndex
        let start_data = pointer.advanced(by: startIndex)
        let raw_data = UnsafeMutablePointer<Int8>.allocate(capacity: data_len)
        memcpy(raw_data, start_data, data_len)
        let string_data = String.init(cString: raw_data)
        free(raw_data)
        return string_data
        
    }
    
    public func getData()->UnsafeMutablePointer<Int8> {
        let pointerData  = UnsafeMutablePointer<Int8>.allocate(capacity: SD.DATA_SIZE)
        memset(pointerData, 0, SD.DATA_SIZE)
        
        //os type + model to int8
        pointerData.pointee = Int8(self.deviceOSType.rawValue)
        let modelPointer = pointerData.advanced(by: SD.LOC_DEVICE_MODEL)
        if let __model = self.deviceModel.toUInt8() {
            memcpy(modelPointer, __model, self.deviceModel.count)
            free(__model)
        }
        
        //sender ip to int8
        let senderIPPointer = pointerData.advanced(by: SD.LOC_SENDER_IP)
        if let __senderIP = self.senderIp.toUInt8() {
            memcpy(senderIPPointer, __senderIP, self.senderIp.count)
            free(__senderIP)
        }
        
        //sender ip to int8
        let senderNamePointer = pointerData.advanced(by: SD.LOC_SENDER_NAME)
        if let __senderName = self.senderName.toUInt8() {
            memcpy(senderNamePointer, __senderName, self.senderName.count)
            free(__senderName)
        }
        
        
        //sender ip to int8
        let receiverIPPointer = pointerData.advanced(by: SD.LOC_RECEIV_IP)
        if let __receiverIP = self.receiverIp.toUInt8() {
            memcpy(receiverIPPointer, __receiverIP, self.receiverIp.count)
            free(__receiverIP)
        }
        
        
        //sender ip to int8
        let receiverNamePointer = pointerData.advanced(by: SD.LOC_RECEIV_NAME)
        if let __receiverName = self.receiverName.toUInt8() {
            memcpy(receiverNamePointer, __receiverName, self.receiverName.count)
            free(__receiverName)
        }
        
        //sender ip to int8
        let statusPointer = pointerData.advanced(by: SD.LOC_STATUS)
        if let __status = self.commStatus.rawValue.toUInt8() {
            memcpy(statusPointer, __status, self.commStatus.rawValue.count)
            free(__status)
        }
        
        //convert comm port to [UInt8]
        let portPointer = pointerData.advanced(by: SD.LOC_COMPORT)
        let __port = self.toByteArray( self.commPort)
        memcpy(portPointer, __port, __port.count)
        
        return pointerData
    }
    
    
    
    func set(Data dataPointer:UnsafeMutablePointer<Int8>){
        let os_type = self.get(rawChar: dataPointer,
                               start: SD.LOC_DEVICE_OS,
                               end: SD.LOC_DEVICE_MODEL)
        
        self.deviceOSType = OSType.init(rawValue: Int(os_type) ?? 0) ?? .unknown
        
        let device_model = self.get(rawChar: dataPointer,
                                    start: SD.LOC_DEVICE_MODEL,
                                    end: SD.LOC_SENDER_IP)
        self.deviceModel = device_model
        
        let sender_ip = self.get(rawChar: dataPointer,
                                 start: SD.LOC_SENDER_IP,
                                 end: SD.LOC_SENDER_NAME)
        self.senderIp = sender_ip
        
        let sender_name = self.get(rawChar: dataPointer,
                                   start: SD.LOC_SENDER_NAME,
                                   end: SD.LOC_RECEIV_IP)
        self.senderName = sender_name
        
        let rec_ip = self.get(rawChar: dataPointer,
                              start: SD.LOC_RECEIV_IP,
                              end: SD.LOC_RECEIV_NAME)
        self.receiverIp = rec_ip
        
        let rec_name = self.get(rawChar: dataPointer,
                                start: SD.LOC_RECEIV_NAME,
                                end: SD.LOC_STATUS)
        self.receiverName = rec_name
        
        let status = self.get(rawChar: dataPointer,
                              start: SD.LOC_STATUS,
                              end: SD.LOC_COMPORT)
        self.commStatus = SOStatus.init(rawValue: status)!
        
        let port = self.get(rawChar: dataPointer,
                            start: SD.LOC_COMPORT,
                            end: SD.DATA_SIZE)
        let intPort = Int(port) ?? 0
        self.commPort = intPort
//        free(dataPointer)//it is not safe to free here, calling function should be responsible to free is data
    }
    
    func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size))
            }
        }
    }

}
extension String {
    
    func toUInt8() -> UnsafeMutablePointer<UInt8>? {
        guard let _data = self.data(using: String.Encoding.utf8) else { return nil}
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: _data.count)
        let stream = OutputStream(toBuffer: buffer, capacity: _data.count)
        stream.open()
        _data.withUnsafeBytes({ (p: UnsafePointer<UInt8>) -> Void in
            stream.write(p, maxLength: _data.count)
        })
        stream.close()
        return buffer
    }
}
