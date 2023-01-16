//
//  RoundButton.swift
//  QuietTimer
//
//  Created by 박준모 on 2023/01/14.
//

import UIKit

class RoundButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.size.width / 2.0
    }
}
