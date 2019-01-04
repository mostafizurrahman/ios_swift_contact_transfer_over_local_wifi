//
//  ContactData.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 31/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import Foundation
import Contacts
import UIKit


class ContactData {
    
    var identifier:String = "X"
    
    //MARK: NAMES DESCRIPTIONS
    var contactName_given:String = ""
    var contactName_family:String = ""
    var contactName_nickname:String = ""
    var contactName_display:String = ""
    var nameSuffix: String = ""
    var namePrefix: String = ""
    
    //MARK: JOB DESCRIPTIONS
    var organizationName: String = ""
    var departmentName: String = ""
    var jobTitle: String = ""
    
    
    //MARK: CONTACT IMAGE
    var contactImageData:Data? = nil
    var contactThumbData:Data? = nil
    var contactHasImage:Bool  = false
    
    
    //MARK: CONTACT BD
    var contactBirthday:DateComponents? = nil
    
    //MARK: CONTACT INFO
    var contactPhoneNumber:[String:AnyObject] = [:]
    var contactEmails:[String:AnyObject] = [:]
    var contactWeburl:[String:AnyObject] = [:]
    var contactAddress:[String:AnyObject] = [:]
    var contactSocials:[String:AnyObject] = [:]
    
    
    init(withData contactData:Data){
        let lengthData = contactData.subdata(in: 0...7)
        let length = lengthData.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
            return ptr.pointee
        }
        let rawContact = contactData.subdata(in: 8...length+7)
        do {
            let jsonData = try JSONSerialization.jsonObject(with: rawContact,
                                                            options: []) as! [String : AnyObject]
            self.identifier = jsonData["identifier"] as? String ?? ""
            self.contactName_given = jsonData["given"] as? String ?? ""
            self.contactName_nickname = jsonData["nickname"] as? String ?? ""
            self.contactName_family = jsonData["family"] as? String ?? ""
            self.contactName_display = jsonData["display"] as? String ?? ""
            self.nameSuffix = jsonData["suffix"] as? String ?? ""
            self.namePrefix = jsonData["prefix"] as? String ?? ""
            
            self.contactHasImage = jsonData["has_image"] as? Bool ?? false
            self.organizationName = jsonData["org"] as? String ?? ""
            
            self.jobTitle = jsonData["job"] as? String ?? ""
            self.departmentName = jsonData["department"] as? String ?? ""
            if let bd = jsonData["birthday"] as? String {
                let array = bd.split(separator: "_")
                if array.count > 2 {
                    var date = DateComponents()
                    date.day = Int(array[0]) ?? 0
                    date.month = Int(array[1]) ?? 0
                    date.year = Int(array[2]) ?? 0
                    self.contactBirthday = date
                } else {
                    self.contactBirthday = nil
                }
            }
            
            self.contactPhoneNumber = jsonData["phones"] as? [String:AnyObject] ?? [:]
            self.contactEmails = jsonData["emails"] as? [String:AnyObject] ?? [:]
            self.contactWeburl = jsonData["webs"] as? [String:AnyObject] ?? [:]
            self.contactSocials = jsonData["social"] as? [String:AnyObject] ?? [:]
            self.contactAddress = jsonData["address"] as? [String:AnyObject] ?? [:]
            
        } catch {
            print(error)
        }
        
        if length < contactData.count - 24 {
            let image_length_data = contactData.subdata(in: length+8...length+31)
            let image_length = image_length_data.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
                return ptr.pointee
            }
            let end_index = length+31+image_length
            let image_data = contactData.subdata(in: length+32...end_index)
            let image = UIImage(data: image_data)
            if image != nil {
                self.contactHasImage = true
                self.contactImageData = image_data
            }
            
            let thumb_length_data = contactData.subdata(in: end_index+1...end_index+23)
            let thumb_length = thumb_length_data.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
                return ptr.pointee
            }
            let end_index2 = end_index+24+thumb_length
            let thumb_data = contactData.subdata(in: end_index+25...end_index2)
            let thumb = UIImage.init(data: thumb_data)
            if thumb != nil {
                self.contactThumbData = thumb_data
            }
        }
    }
    
    init(withContact contact:CNContact){
        
        self.identifier = contact.identifier
        self.contactName_given = contact.givenName
        self.contactName_family = contact.familyName
        self.contactName_nickname = contact.nickname
        self.contactName_display = (self.contactName_given + " "
            + self.contactName_family + " "
            + self.contactName_nickname).replacingOccurrences(of: "  ", with: " ")
        
        self.nameSuffix = contact.nameSuffix
        self.namePrefix = contact.namePrefix
        
        if contact.organizationName != "" {
            self.organizationName = contact.organizationName
        }
        if contact.departmentName != "" {
            self.departmentName = contact.departmentName
        }
        if contact.jobTitle != "" {
            self.jobTitle = contact.jobTitle
        }
        self.contactHasImage = contact.imageDataAvailable
        if self.contactHasImage {
            if let imageData = contact.imageData {
                if let image = UIImage.init(data: imageData) {
                    self.contactImageData = image.jpegData(compressionQuality: 0.99)
                }
            }
            self.contactThumbData = contact.thumbnailImageData
        }
        
        if let _ = contact.birthday?.date {
            self.contactBirthday = contact.birthday
        }
    
        if contact.phoneNumbers.count > 0 {
            for phoneNumber in contact.phoneNumbers {
                guard let number_label = phoneNumber.label else {
                    continue
                }
                let phone_number = phoneNumber.value.stringValue
                self.contactPhoneNumber[number_label]  = phone_number as AnyObject
            }
        }
        
        if contact.emailAddresses.count > 0 {
            for email in contact.emailAddresses {
                guard let email_label = email.label else {
                    continue
                }
                let email_address = email.value as String
                self.contactEmails[email_label] = email_address as AnyObject
            }
        }
        
        if contact.urlAddresses.count > 0 {
            for url in contact.urlAddresses {
                guard let url_label = url.label else {
                    continue
                }
                let url_value = url.value as String
                self.contactWeburl[url_label] = url_value as AnyObject
            }
        }
        
        if contact.postalAddresses.count > 0 {
            for address in contact.postalAddresses {
                guard let address_label = address.label else {
                    continue
                }
                let address_value = address.value as CNPostalAddress
                var postal = [String:String]()
                postal["street"] = address_value.street
                postal["state"] = address_value.state
                postal["city"] = address_value.city
                postal["postalCode"] = address_value.postalCode
                postal["country"] = address_value.country
                postal["isoCountryCode"] = address_value.isoCountryCode
                if #available(iOS 10.3, *) {
                    postal["subLocality"] = address_value.subLocality
                    postal["subAdministrativeArea"] = address_value.subAdministrativeArea
                }
                self.contactAddress[address_label] = postal as AnyObject
            }
        }
        
        if contact.socialProfiles.count > 0 {
            for social in contact.socialProfiles {
                guard let social_label = social.label else {
                    continue
                }
                var social_value = [String:String]()
                let profile = social.value
                social_value["urlString"] = profile.urlString
                social_value["username"] = profile.username
                social_value["userIdentifier"] = profile.userIdentifier
                social_value["service"] = profile.service
                self.contactSocials[social_label] = social_value as AnyObject
            }
        }
    }
    
    
    func getData()->Data {
        let contactData = NSMutableData()
        let dictionary = self.getMap()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary,
                                                      options:.prettyPrinted)
            var dataLength: NSInteger = jsonData.count
            let lengthData = Data(bytes:&dataLength,
                                  count:MemoryLayout.size(ofValue: dataLength))
            print(lengthData.count)
            contactData.append(lengthData)
            contactData.append(jsonData)
        } catch  {
            print(error)
        }
        var length_data_image:Data = Data()
        if var image_data  = self.contactImageData {
            var count = image_data.count
            length_data_image = Data(bytes: &count,
                                 count: MemoryLayout.size(ofValue: image_data))
            print(length_data_image.count)
            contactData.append(length_data_image)
            contactData.append(image_data)
            if var image_data  = self.contactThumbData {
                count = image_data.count
                length_data_image = Data(bytes: &count,
                                         count: MemoryLayout.size(ofValue: image_data))
                print(length_data_image.count)
                contactData.append(length_data_image)
                contactData.append(image_data)
            }
        }
        return contactData as Data
    }
    
    func getMap()->[String:AnyObject] {
        
        var data = [String:AnyObject]()
        data["identifier"] = self.identifier as AnyObject
        data["given"] = self.contactName_given as AnyObject
        data["nickname"] = self.contactName_nickname  as AnyObject
        data["family"] = self.contactName_family  as AnyObject
        data["display"] = self.contactName_display as AnyObject
        
        data["suffix"] = self.nameSuffix as AnyObject
        data["prefix"] = self.namePrefix as AnyObject
        
        data["has_image"] = self.contactHasImage as AnyObject
        
        data["org"] = self.organizationName as AnyObject
        data["job"] = self.jobTitle as AnyObject
        data["department"] = self.departmentName as AnyObject
        if let bday = self.contactBirthday {
            let day = String(format: "%d", bday.day ?? 0)
            let mon = String(format: "%d", bday.month ?? 0)
            let yer = String(format: "%d", bday.year ?? 0)
            let bd = "\(day)_\(mon)_\(yer)"
            data["birthday"] = bd as AnyObject
        } else {
            data["birthday"] = "" as AnyObject
        }
        
        
        
        data["phones"] = self.contactPhoneNumber as AnyObject
        data["emails"] = self.contactEmails as AnyObject
        data["webs"] = self.contactWeburl as AnyObject
        data["social"] = self.contactSocials as AnyObject
        data["address"] = self.contactAddress as AnyObject
        return data
    }
    
}
extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
}
extension Data {
    var uint8: UInt8 {
        get {
            var number: UInt8 = 0
            self.copyBytes(to:&number, count: MemoryLayout<UInt8>.size)
            return number
        }
    }
    var uint16: UInt16 {
        get {
            let i16array = self.withUnsafeBytes {
                UnsafeBufferPointer<UInt16>(start: $0, count: self.count/2).map(UInt16.init(littleEndian:))
            }
            return i16array[0]
        }
    }
    var uint32: UInt32 {
        get {
            let i32array = self.withUnsafeBytes {
                UnsafeBufferPointer<UInt32>(start: $0, count: self.count/2).map(UInt32.init(littleEndian:))
            }
            return i32array[0]
        }
    }
    var uuid: NSUUID? {
        get {
            var bytes = [UInt8](repeating: 0, count: self.count)
            self.copyBytes(to:&bytes, count: self.count * MemoryLayout<UInt32>.size)
            return NSUUID(uuidBytes: bytes)
        }
    }
    var stringASCII: String? {
        get {
            return NSString(data: self, encoding: String.Encoding.ascii.rawValue) as String?
        }
    }
    var stringUTF8: String? {
        get {
            return NSString(data: self, encoding: String.Encoding.utf8.rawValue) as String?
        }
    }
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}
