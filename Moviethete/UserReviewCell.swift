//
//  UserReviewCell.swift
//  Moviethete
//
//  Created by Mike on 9/4/15.
//  Copyright © 2015 BIBORAM. All rights reserved.
//

import UIKit

class UserReviewCell: UITableViewCell {

  @IBOutlet weak var profileImage: UIImageView!
  @IBOutlet weak var userName: UILabel!
  @IBOutlet weak var review: UITextView!
  @IBOutlet weak var timeSincePosted: UILabel!
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
