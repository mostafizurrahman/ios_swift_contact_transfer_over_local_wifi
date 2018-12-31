//
//  ContactParser.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 31/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//
import UIKit
import Foundation
import Contacts

class ContactParser: NSObject {
    
    var shoulNotify = true
    var phoneContacts:[ContactData] = []
    static let parser = ContactParser()
    
    override init() {
        super.init()
        DispatchQueue.global().async {
            self.findContacts()
        }
    }
    
    func findContacts() {
        let store = CNContactStore()
        
        let keysToFetch = [CNContactIdentifierKey,
                           CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                           CNContactImageDataKey,
                           CNContactBirthdayKey,
                           CNContactImageDataAvailableKey,
                           CNContactThumbnailImageDataKey,
                           CNContactEmailAddressesKey,
                           CNContactJobTitleKey,
                           CNContactDepartmentNameKey,
                           CNContactNoteKey,
                           CNContactDatesKey,
                           CNContactUrlAddressesKey,
                           CNContactSocialProfilesKey,
                           CNContactPostalAddressesKey,
                           CNContactOrganizationNameKey,
                           CNContactFamilyNameKey,
                           CNContactGivenNameKey,
                           CNContactPhoneNumbersKey] as! [CNKeyDescriptor]
        
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        do
        {
            try store.enumerateContacts(with: fetchRequest, usingBlock: { ( contact,  stop) in
                let contactData = ContactData(withContact: contact)
                self.phoneContacts.append(contactData)
            })
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        
        if self.shoulNotify {
            self.shoulNotify = false
            let notification = Notification(name: Notification.Name(rawValue: "ContactNotification"),
                                            object: nil,
                                            userInfo: ["total_contact":self.phoneContacts.count])
            DispatchQueue.main.async {
                NotificationCenter.default.post(notification)
            }
        }
        
    }

}
