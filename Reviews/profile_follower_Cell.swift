//
//  profile_follower_Cell.swift
//  Moviethete
//
//  Created by Admin on 25/07/15.
//  Copyright (c) 2015 Admin. All rights reserved.
//

import UIKit

class profile_follower_Cell: UITableViewCell {

    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
