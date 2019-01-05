//
//  ContactTableViewCell.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 31/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit

protocol ContactDetailsDelegate:NSObjectProtocol {
    func onInfoClicked(atCell tableCell:ContactTableViewCell)
}

class ContactTableViewCell: UITableViewCell {

    @IBOutlet weak var contactTitle: UILabel!
    @IBOutlet weak var contactNumber: UILabel!
    @IBOutlet weak var contactThumb: UIImageView!
    
    weak var contactDelegate:ContactDetailsDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func showContact(_ sender: Any) {
        if let __delegate = self.contactDelegate {
             weak var this = self
             if let _this = this {
                __delegate.onInfoClicked(atCell:_this)
            }
        }
    }
}
