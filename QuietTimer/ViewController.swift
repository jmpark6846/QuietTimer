//
//  ViewController.swift
//  QuietTimer
//
//  Created by 박준모 on 2023/01/10.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    var referenceDate: Date!
    var selectedTime: Date!
    var currentTime: Date!
    var isTimerOn = false
    var timer: Timer!
    var hour = 0
    var minute = 0
    var second = 0
    
    @IBOutlet var pvTime: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pvTime.dataSource = self
        pvTime.delegate = self
        
        
        // set default time
        referenceDate = setDatetime(0, 0, 0)
        selectedTime = setDatetime(hour, minute, second)
    }
    
    func setDatetime(_ hour: Int, _ minute: Int, _ second: Int) -> Date {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: "2000-01-01 \(hour):\(minute):\(second)")!
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 24
        } else if component == 1 {
            return 60
        } else {
            return 60
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            hour = row
        case 1:
            minute = row
        case 2:
            second = row
        default:
            return
        }
        
        selectedTime = setDatetime(hour, minute, second)
    }
    
    
    @IBAction func btnStartTapped(_ sender: UIButton) {
        currentTime = selectedTime
        
        if !isTimerOn {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
            isTimerOn = true
        }
        
    }
    
    @objc func timeUpdate(){
        currentTime.addTimeInterval(-1)
        if Int(currentTime.timeIntervalSince(referenceDate)) <= 0 {
            isTimerOn = false
            timer.invalidate()
        }
    }
}

