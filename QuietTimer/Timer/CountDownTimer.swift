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
    var timer: Timer?
    var updateHandler:  (() -> Void)?
    
    @objc func timeUpdate(){
        
        if remainingTime <= 0 {
            emptyTimer()
            status = .READY
        }
        
        if updateHandler != nil {
            updateHandler!()
        }
    }
    
    func start(){
        if status != .READY {
            fatalError("준비상태에서만 시작할 수 있습니다.")
        }
        
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
        if status == .READY {
            fatalError("이미 준비(정지된) 상태입니다.")
        }
        status = .READY
        emptyTimer()
        endTime = 0
        pausedAt = nil
    }
    
    func pause(){
        if status == .PAUSED && pausedAt != nil {
            fatalError("이미 일시정지 상태입니다")
        }
        status = .PAUSED
        emptyTimer()
        pausedAt = Date()
        
    }
    
    func resume(){
        if status != .PAUSED && pausedAt != nil  {
            fatalError("일시정지된 상태에서만 resume 할 수 있습니다.")
        }
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
