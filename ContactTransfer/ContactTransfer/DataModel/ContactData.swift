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
    
    let identifier:String
    
    //MARK: NAMES DESCRIPTIONS
    let contactName_given:String
    let contactName_family:String
    let contactName_nickname:String
    let contactName_display:String
    let nameSuffix: String
    let namePrefix: String
//    let phoneticGivenName: String
//    let phoneticMiddleName: String
//    let phoneticFamilyName: String
    
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
//        self.phoneticGivenName = contact.phoneticGivenName == "" ? "" : contact.phoneticGivenName
//        self.phoneticFamilyName = contact.phoneticFamilyName == "" ? "" : contact.phoneticFamilyName
//        self.phoneticMiddleName = contact.phoneticMiddleName == "" ? "" : contact.phoneticMiddleName
        
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

}
