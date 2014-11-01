//
//  PickerViewCell.swift
//  D-Day
//
//  Created by Moon Hayden on 2014. 11. 1..
//  Copyright (c) 2014년 Hayden. All rights reserved.
//

import UIKit

class PickerViewCell: UITableViewCell {

    @IBOutlet weak var pickerView: UIPickerView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
