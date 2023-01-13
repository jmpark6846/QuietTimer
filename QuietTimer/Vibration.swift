//
//  Vibration.swift
//  QuietTimer
//
//  Created by 박준모 on 2023/01/11.
//

import AVFoundation
import AudioToolbox
import UIKit

enum Vibration {
    @available(iOS 10.0, *)
    case light
    case medium
    case old
    
    static public func vibrate(){
        if #available(iOS 10.0, *) {
            Vibration.medium.vibrate()
        }else{
            Vibration.old.vibrate()
        }
    }
    
    public func vibrate() {
        switch self {
        case .light:
            if #available(iOS 10.0, *){
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        case .medium:
            if #available(iOS 10.0, *){
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        case .old:
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }

    }
}
