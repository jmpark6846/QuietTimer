//
//  Timer.swift
//  QuietTimer
//
//  Created by 박준모 on 2023/01/12.
//

import Foundation

class CountDownTimer {
    let TIMER_INTERVAL = 0.05
    var status: TimerStatus = .READY
    var selectedTime: TimeInterval = 0.0
    var endTime: TimeInterval = 0.0
    var remainingTime: TimeInterval {
        if pausedAt != nil {
            return endTime - pausedAt!.timeIntervalSinceReferenceDate
        }
        
        if endTime == 0 {
            return 0
        }
        
        return endTime - Date.timeIntervalSinceReferenceDate
    }
    var pausedAt: Date?
    var timer: Timer? // TODO
    var updateHandler:  (() -> Void)?
    
    @objc func timeUpdate(){
        
        if remainingTime <= 0 {
            timer?.invalidate()
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
        
        if timer != nil {
            fatalError()
        }
        status = .START
        endTime = Date.timeIntervalSinceReferenceDate + selectedTime
        setTimer()
        
    }
    
    func stop(){
        if timer == nil {
            fatalError()
        }
        status = .READY
        emptyTimer()
        endTime = 0
    }
    
    func pause(){
        status = .PAUSED
        emptyTimer()
        pausedAt = Date()
        
    }
    
    func resume(){
        status = .START
        endTime += Date.timeIntervalSinceReferenceDate - pausedAt!.timeIntervalSinceReferenceDate
        pausedAt = nil
        setTimer()
    }
    
    func emptyTimer(){
        timer?.invalidate()
        timer = nil
    }
    
    func setTimer(){
        timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
    }
}
