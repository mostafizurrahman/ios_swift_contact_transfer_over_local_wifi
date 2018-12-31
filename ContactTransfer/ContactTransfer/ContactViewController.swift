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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.cnparser.shoulNotify {
            NotificationCenter.default.addObserver(self, selector: #selector(onContactParsed(_:)),
                                                   name: Notification.Name(rawValue: "ContactNotification"),
                                                   object: nil)
        }
        // Do any additional setup after loading the view.
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
   
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.searchActive) {
            return filterContacts.count
        }
        return deviceContacts.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactTableViewCell
        
        let contactData = self.searchActive ?
            self.filterContacts[indexPath.row] :
            self.deviceContacts[indexPath.row]
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
