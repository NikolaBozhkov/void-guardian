//
//  UIColor+Extensions.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 6.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension UIColor {
    convenience init(_ color: vector_float3) {
        self.init(red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: 1)
    }
}
