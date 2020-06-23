//
//  RoundedCornerBackGround.swift
//  MyTVForIOS
//
//  Created by lvvi on 2020/3/22.
//  Copyright © 2020 lvvi. All rights reserved.
//

import UIKit

class RoundedCornerBackGround: UIView {

    override func draw(_ rect: CGRect) {
        let roundedArc = UIBezierPath(roundedRect: bounds, cornerRadius: 18.0)
        roundedArc.addClip()
        let bgColor = #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 0.8490207619)
        bgColor.setFill()
        roundedArc.fill()
    }

}
