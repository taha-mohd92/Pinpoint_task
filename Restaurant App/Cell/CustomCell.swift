//
//  CustomCell.swift
//  Restaurant App
//
//  Created by Mohd Taha on 21/10/2022.
//

import Foundation
import UIKit

class CustomCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
