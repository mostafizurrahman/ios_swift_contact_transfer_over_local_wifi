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

    
    @IBOutlet weak var bottomSpaceSendContact: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceHideKeybord: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceCollections: NSLayoutConstraint!
    @IBOutlet weak var contactTableView: UITableView!
    fileprivate var searchActive = false
    fileprivate let cnparser = ContactParser.parser
    fileprivate var deviceContacts:[ContactData] = []
    fileprivate var filterContacts:[ContactData] = []
    fileprivate var deselectedContacts:[String] = []
    var searchBar:UISearchBar!
    var keybordSize:CGRect?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar = UISearchBar(frame: CGRect(x:0, y:0, width:self.view.frame.width * 0.75, height:44))
        self.searchBar.placeholder = "search contact..."
        self.searchBar.delegate = self
        let navBarButton = UIBarButtonItem(customView:self.searchBar)
        self.navigationItem.rightBarButtonItem = navBarButton
        NotificationCenter.default.addObserver(self, selector: #selector(ContactViewController.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContactViewController.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if self.cnparser.shoulNotify {
            NotificationCenter.default.addObserver(self, selector: #selector(onContactParsed(_:)),
                                                   name: Notification.Name(rawValue: "ContactNotification"),
                                                   object: nil)
        } else {
            self.deviceContacts = self.cnparser.phoneContacts
            self.contactTableView.reloadData()
        }
        if let _value = UserDefaults.standard.value(forKey: "keyborad_frame") {
            self.keybordSize = (_value as! NSValue).cgRectValue
        }
        
        // Do any additional setup after loading the view.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "ContactNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc func keyboardWillShow(notification: Notification) {
        let bottomSpace:CGFloat = UIScreen.main.bounds.height / 2.65
        self.bottomSpaceCollections.constant = bottomSpace
        self.bottomSpaceHideKeybord.constant = bottomSpace - 45
        self.bottomSpaceSendContact.constant = bottomSpace - 45
        UIView.animate(withDuration: 0.4) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if let _ = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey]
            as? NSValue)?.cgRectValue {
            self.bottomSpaceCollections.constant = 45
            self.bottomSpaceHideKeybord.constant = 2.5
            self.bottomSpaceSendContact.constant = 2.5
            UIView.animate(withDuration: 0.4) {
                self.view.layoutIfNeeded()
            }
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
    
    @IBAction func hideKeybord(_ sender: Any) {
        self.view.endEditing(true)
        self.searchBar.endEditing(true)
    }
    

}

extension ContactViewController:UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        self.searchActive = true;
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
                if contactData.contactName_display.lowercased().contains(searchText.lowercased()) {
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
            let value = Array(contactData.contactPhoneNumber)[0].value
            tableCell.contactNumber.text = "\(value)"
        }
        if let thumb_data = contactData.contactThumbData {
            tableCell.contactThumb.image = UIImage.init(data: thumb_data)
        } else {
            tableCell.contactThumb.image = UIImage.init(named: "woman")
        }
        if tableCell.contactThumb.layer.cornerRadius == 0 {
            tableCell.contactThumb.layer.cornerRadius = tableCell.contactThumb.frame.size.width/2
            tableCell.contactThumb.layer.masksToBounds = true
            tableCell.contactThumb.layer.borderColor = UIColor.white.cgColor
            tableCell.contactThumb.layer.borderWidth = 0.8
        }
        
        return tableCell
    }
    
}
