//
//  ViewController.swift
//  QuietTimer
//
//  Created by 박준모 on 2023/01/10.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    let TRANSITION_INTERVAL = 0.1
    var referenceDate: Date!
    var selectedTime: Date!
    var currentTime: Date!
    var isTimerOn = false
    var timer: Timer!
    var hour = 0
    var minute = 0
    var second = 0
    
    var lbTime: UILabel!
    var pvTime: UIPickerView!
    var btnStart: UIButton!
    var btnStop: UIButton!
    var btnPause: UIButton!
    var btnStack: UIStackView!
    var btnResume: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        pvTime.dataSource = self
        pvTime.delegate = self
        
        // set default time
        referenceDate = getDate(0, 0, 0)
        selectedTime = getDate(hour, minute, second)
    }
    
    
    func setupUI(){
        pvTime = UIPickerView()
        pvTime.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pvTime)
        pvTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pvTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        
        lbTime = UILabel()
        lbTime.font = UIFont.systemFont(ofSize: 30.0)
        
        btnStart = UIButton()
        btnStart.setTitleColor(UIColor.black, for: .normal)
        btnStart.setTitle("Start", for: .normal)
        btnStart.addTarget(self, action: #selector(btnStartTapped(_:)), for: .touchUpInside)
        view.addSubview(btnStart)
        btnStart.translatesAutoresizingMaskIntoConstraints = false
        btnStart.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        btnStart.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        btnStop = UIButton()
        btnStop.setTitle("Stop", for: .normal)
        btnStop.setTitleColor(.black, for: .normal)
        btnStop.addTarget(self, action: #selector(btnStopTapped(_:)), for: .touchUpInside)
        btnStop.translatesAutoresizingMaskIntoConstraints = false
        
        btnPause = UIButton()
        btnPause.setTitle("Pause", for: .normal)
        btnPause.setTitleColor(.black, for: .normal)
        btnPause.addTarget(self, action: #selector(btnPauseTapped(_:)), for: .touchUpInside)
        btnPause.translatesAutoresizingMaskIntoConstraints = false
        
        btnStack = UIStackView(arrangedSubviews: [btnStop, btnPause])
        btnStack.axis = .horizontal
        btnStack.distribution = .fillEqually
        btnStack.spacing = 5.0
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        
        btnResume = UIButton()
        btnResume.setTitle("Resume", for: .normal)
        btnResume.setTitleColor(.black, for: .normal)
        btnResume.addTarget(self, action: #selector(btnResumeTapped(_:)), for: .touchUpInside)
    }
    
    @objc func btnPauseTapped(_ sender: UIButton){
        timer.invalidate()
        btnPause.removeFromSuperview()
        btnStack.addArrangedSubview(btnResume)
    }
    
    @objc func btnResumeTapped(_ sender: UIButton) throws {
        if timer != nil && timer.isValid {
            throw TimerError.DuplicatedTimer
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)

        btnResume.removeFromSuperview()
        btnStack.addArrangedSubview(btnPause)
    }
    
    @objc func btnStartTapped(_ sender: UIButton) throws {
        if hour == 0 && minute == 0 && second == 0 {
            return
        }
        
        if !isTimerOn {
            // time label
            view.addSubview(lbTime)
            lbTime.translatesAutoresizingMaskIntoConstraints = false
            lbTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            lbTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
            lbTime.text = formattedTimeText(selectedTime)
            
            UIView.transition(from: pvTime, to: lbTime!, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve)
            currentTime = selectedTime
            
            if timer != nil && timer.isValid {
                throw TimerError.DuplicatedTimer
            }
            
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timeUpdate), userInfo: nil, repeats: true)
            isTimerOn = true
            
            // buttons
            view.addSubview(btnStack)
            btnStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            btnStack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            UIView.transition(from: btnStart, to: btnStack, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
        }
    }
    
    @objc func btnStopTapped(_ sender: UIButton){
        guard let timer = timer else {
            return
        }

        timer.invalidate()
        isTimerOn = false
        
        view.addSubview(pvTime)
        pvTime.translatesAutoresizingMaskIntoConstraints = false
        pvTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pvTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        UIView.transition(from: lbTime, to: pvTime, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
        
        view.addSubview(btnStart)
        btnStart.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        btnStart.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        UIView.transition(from: btnStack, to: btnStart, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
        
        btnResume.removeFromSuperview()
        btnStack.addArrangedSubview(btnPause)
    }
    
    
    @objc func timeUpdate(){
        currentTime.addTimeInterval(-1)
        
        guard let lbTime = lbTime else { return }
        let timeText = formattedTimeText(currentTime)
        lbTime.text = timeText
        
        if Int(currentTime.timeIntervalSince(referenceDate)) <= 0 {
            timer?.invalidate()
            isTimerOn = false
            
            view.addSubview(pvTime)
            pvTime.translatesAutoresizingMaskIntoConstraints = false
            pvTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            pvTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
            UIView.transition(from: lbTime, to: pvTime, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
            
            view.addSubview(btnStart)
            btnStart.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            btnStart.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            UIView.transition(from: btnStack, to: btnStart, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
            print("time's up!")
        }
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
        
        selectedTime = getDate(hour, minute, second)
    }
    
    func formattedTimeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    func getDate(_ hour: Int, _ minute: Int, _ second: Int) -> Date {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: "2000-01-01 \(hour):\(minute):\(second)")!
    }
}

