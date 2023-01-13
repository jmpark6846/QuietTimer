//
//  Timer.swift
//  QuietTimer
//
//  Created by 박준모 on 2023/01/12.
//

import Foundation

class JMTimer {
    var selectedTime: TimeInterval = 0.0
    var remainingTime: TimeInterval = 0.0
    var timer: Timer!
    var updateHandler:  (() -> Void)?
    
    
    @objc func timeUpdate(){
        remainingTime -= 1
        if remainingTime <= 0 {
            timer.invalidate()
            timer = nil
        }
        
        if updateHandler != nil {
            updateHandler!()
        }
    }
    
    func start(){
        if selectedTime <= 0 {
            return
        }
        
        if timer == nil {
            remainingTime = selectedTime
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
        }
    }
    
    func stop(){
        if timer != nil && timer.isValid {
            timer.invalidate()
            timer = nil
            remainingTime = 0
        }
    }
    
    func pause(){
        if timer != nil && timer.isValid {
            timer.invalidate()
            timer = nil
        }
    }
    
    func resume(){
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
        }
    }
}
