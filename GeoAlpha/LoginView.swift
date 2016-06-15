//
//  LoginView.swift
//  GeoAlpha
//
//  Created by Med Beji on 13/06/2016.
//  Copyright © 2016 alphalab. All rights reserved.
//

import UIKit

class LoginView: UIView {
    
    override func awakeFromNib() {
        layer.cornerRadius = 3.0
        layer.shadowColor = UIColor(red:SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.5).CGColor
        layer.shadowOpacity = 0.9
        layer.shadowRadius = 6.0
        layer.shadowOffset = CGSizeMake(0.0, 2.5)
    }
}
