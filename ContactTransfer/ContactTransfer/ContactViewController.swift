//
//  ContactViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 31/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit
import Contacts

class ContactViewController: UIViewController {

    
    @IBOutlet weak var contactTableView: UITableView!
    fileprivate var searchActive = false
    fileprivate let cnparser = ContactParser.parser
    fileprivate var deviceContacts:[ContactData] = []
    fileprivate var filterContacts:[ContactData] = []
    fileprivate var deselectedContacts:[String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ContactViewController.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContactViewController.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if self.cnparser.shoulNotify {
            NotificationCenter.default.addObserver(self, selector: #selector(onContactParsed(_:)),
                                                   name: Notification.Name(rawValue: "ContactNotification"),
                                                   object: nil)
        }
        // Do any additional setup after loading the view.
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey]
            as? NSValue)?.cgRectValue {
            self.contactTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
           
        }
        
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if let _ = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey]
            as? NSValue)?.cgRectValue {
            self.contactTableView.contentInset = UIEdgeInsets.zero
        }
    }
    
    //on main thread
    @objc func onContactParsed(_ notification:Notification){
        self.deviceContacts = self.cnparser.phoneContacts
        self.contactTableView.reloadData()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    

}

extension ContactViewController:UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        DispatchQueue.global().async {
            self.filterContacts = self.deviceContacts.filter({ (contactData) -> Bool in
                if contactData.contactName_display.contains(searchText) {
                    return true
                }
                for phone in contactData.contactPhoneNumber.values {
                    if phone.contains(searchText) {
                        return true
                    }
                }
                return false
            })
            if(self.filterContacts.count == 0){
                self.searchActive = false
            } else {
                self.searchActive = true
            }
            DispatchQueue.main.async {
                self.contactTableView.reloadData()
            }
        }
    }
    
//    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
//        return false
//    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.searchActive) {
            return filterContacts.count
        }
        return deviceContacts.count;
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        tableView.deselectRow(at: indexPath, animated: true)
        let tableRow = tableView.cellForRow(at: indexPath) as! ContactTableViewCell
        let contactData = self.searchActive ?
            self.filterContacts[indexPath.row] :
            self.deviceContacts[indexPath.row]
        if deselectedContacts.contains(contactData.identifier) {
            tableRow.accessoryType = .checkmark
            self.deselectedContacts = self.deselectedContacts.filter{$0 != contactData.identifier}
        } else {
            tableRow.accessoryType = .none
            deselectedContacts.append(contactData.identifier)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactTableViewCell
        
        let contactData = self.searchActive ?
            self.filterContacts[indexPath.row] :
            self.deviceContacts[indexPath.row]
        tableCell.accessoryType = self.deselectedContacts.contains(contactData.identifier) ?
            .none : .checkmark
        tableCell.contactTitle.text = contactData.contactName_display
        if contactData.contactPhoneNumber.values.count > 0 {
            let key = Array(contactData.contactPhoneNumber)[0].key
            let value = Array(contactData.contactPhoneNumber)[0].value
            tableCell.contactNumber.text = "\(key) : \(value)"
        }
        if let thumb_data = contactData.contactThumbData {
            tableCell.contactThumb.image = UIImage.init(data: thumb_data)
        }
        
        return tableCell
    }
    
}
