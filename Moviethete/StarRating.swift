//
//  StarRating.swift
//  Moviethete
//
//  Created by Mike on 9/3/15.
//  Copyright © 2015 BIBORAM. All rights reserved.
//

import UIKit
import HCSStarRatingView

class StarRating: UITableViewCell {
  
  @IBOutlet weak var rating: HCSStarRatingView!

    override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
