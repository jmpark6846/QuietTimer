//
//  ViewController.swift
//  QuietTimer
//
//  Created by 박준모 on 2023/01/10.
//

import UIKit
import UserNotifications
import AudioToolbox


class ViewController: UIViewController {
    let TRANSITION_INTERVAL = 0.1
    
    var selectedTime: TimeInterval = 0.0
    var remainingTime: TimeInterval = 0.0
    var timer: Timer!
    
    var pvTimeData: [Int] = [0, 0, 0]
        
    var lbTime: UILabel!
    var pvTime: UIPickerView!
    var btnStart: UIButton!
    var btnStop: UIButton!
    var btnPause: UIButton!
    var btnStack: UIStackView!
    var btnResume: UIButton!
    
    override func loadView() {
        super.loadView()
        setupUI()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: nil, using: saveBackgroundEnterTime(notification:))
        NotificationCenter.default.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: nil, using: calculateCurrentTimeWhenEnterForeground(notification:))
        
        pvTime.dataSource = self
        pvTime.delegate = self
    }
    
    func saveBackgroundEnterTime(notification: Notification){
        if timer != nil && timer.isValid {
            timer.invalidate()
            timer = nil
            UserDefaults.standard.set(Date(), forKey: UserDefaultKey.BACKGROUND_ENTER_TIME.rawValue)
            UserDefaults.standard.set(remainingTime, forKey: UserDefaultKey.REMAINING_TIME.rawValue)
            UserDefaults.standard.set(selectedTime, forKey: UserDefaultKey.SELECTED_TIME.rawValue)
        }
    }
    
    func calculateCurrentTimeWhenEnterForeground(notification: Notification){
        guard let backgroundEnterTime = UserDefaults.standard.object(forKey: UserDefaultKey.BACKGROUND_ENTER_TIME.rawValue) as? Date else { return }
        
        let remainingTimeUserDefaults = UserDefaults.standard.double(forKey: UserDefaultKey.REMAINING_TIME.rawValue)
        let selectedTimeUserDefaults = UserDefaults.standard.double(forKey: UserDefaultKey.SELECTED_TIME.rawValue)
        
        UserDefaults.standard.set(nil, forKey: UserDefaultKey.BACKGROUND_ENTER_TIME.rawValue)
        UserDefaults.standard.set(0, forKey: UserDefaultKey.SELECTED_TIME.rawValue)
        UserDefaults.standard.set(0, forKey: UserDefaultKey.REMAINING_TIME.rawValue)

        let backgroundTimeInterval =  Date().timeIntervalSince(backgroundEnterTime)
        selectedTime = selectedTimeUserDefaults
        remainingTime = remainingTimeUserDefaults
        remainingTime -= backgroundTimeInterval
        
        if remainingTime <= 0 {
            btnStopTapped(btnStop)
        }else{
            setupTimerOnUI()
            UIView.transition(from: pvTime, to: lbTime!, duration: TRANSITION_INTERVAL, options: .showHideTransitionViews)
            UIView.transition(from: btnStart, to: btnStack, duration: TRANSITION_INTERVAL, options: .showHideTransitionViews)
            
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timeUpdate), userInfo: nil, repeats: true)
            scheduleNotification()
        }
    }
    
    func setupUI(){
        pvTime = UIPickerView()
        view.addSubview(pvTime)
        pvTime.translatesAutoresizingMaskIntoConstraints = false
        pvTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pvTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        
        lbTime = UILabel()
        lbTime.font = UIFont.systemFont(ofSize: 30.0)
        
        btnStart = UIButton()
//        btnStart.setTitleColor(UIColor.black, for: .normal)
        btnStart.setTitle("Start", for: .normal)
        btnStart.addTarget(self, action: #selector(btnStartTapped(_:)), for: .touchUpInside)
        view.addSubview(btnStart)
        btnStart.translatesAutoresizingMaskIntoConstraints = false
        btnStart.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        btnStart.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        btnStop = UIButton()
        btnStop.setTitle("Stop", for: .normal)
//        btnStop.setTitleColor(.black, for: .normal)
        btnStop.addTarget(self, action: #selector(btnStopTapped(_:)), for: .touchUpInside)
        btnStop.translatesAutoresizingMaskIntoConstraints = false
        
        btnPause = UIButton()
        btnPause.setTitle("Pause", for: .normal)
//        btnPause.setTitleColor(.black, for: .normal)
        btnPause.addTarget(self, action: #selector(btnPauseTapped(_:)), for: .touchUpInside)
        btnPause.translatesAutoresizingMaskIntoConstraints = false
        
        btnStack = UIStackView(arrangedSubviews: [btnStop, btnPause])
        btnStack.axis = .horizontal
        btnStack.distribution = .fillEqually
        btnStack.spacing = 5.0
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        
        btnResume = UIButton()
        btnResume.setTitle("Resume", for: .normal)
//        btnResume.setTitleColor(.black, for: .normal)
        btnResume.addTarget(self, action: #selector(btnResumeTapped(_:)), for: .touchUpInside)
    }
    
    
    @objc func btnPauseTapped(_ sender: UIButton){
        timer.invalidate()
        timer = nil
        removeNotification()
        
        btnPause.removeFromSuperview()
        btnStack.addArrangedSubview(btnResume)
    }
    
    @objc func btnResumeTapped(_ sender: UIButton) {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
        
        scheduleNotification()
        
        btnResume.removeFromSuperview()
        btnStack.addArrangedSubview(btnPause)
    }
    
    func setupTimerOnUI(){
        view.addSubview(lbTime)
        lbTime.translatesAutoresizingMaskIntoConstraints = false
        lbTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        lbTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        lbTime.text = formattedTimeText(remainingTime)
        
        view.addSubview(btnStack)
        btnStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        btnStack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    @objc func btnStartTapped(_ sender: UIButton) {
        remainingTime = selectedTime
        
        setupTimerOnUI()
        UIView.transition(from: pvTime, to: lbTime!, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve)
        UIView.transition(from: btnStart, to: btnStack, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve)
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timeUpdate), userInfo: nil, repeats: true)
        
        scheduleNotification()
        
    }
    
    @objc func btnStopTapped(_ sender: UIButton){
        if timer != nil && timer.isValid {
            timer.invalidate()
            timer = nil
        }
        
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
        
        removeNotification()
    }
    
    
    @objc func timeUpdate(){
        remainingTime -= 1
        guard let lbTime = lbTime else { return }
        lbTime.text = formattedTimeText(remainingTime)
        
        if remainingTime <= 0 {
            timer.invalidate()
            timer = nil
            
            let alert = UIAlertController(title: "Alarm", message: "Time's up!", preferredStyle: .actionSheet)
            let action = UIAlertAction(title: "ok", style: .default) { action in
                self.view.addSubview(self.pvTime)
                self.pvTime.translatesAutoresizingMaskIntoConstraints = false
                self.pvTime.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                self.pvTime.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
                UIView.transition(from: self.lbTime, to: self.pvTime, duration: self.TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
                
                self.view.addSubview(self.btnStart)
                self.btnStart.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                self.btnStart.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                UIView.transition(from: self.btnStack, to: self.btnStart, duration: self.TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
                
                self.removeNotification()
            }
            alert.addAction(action)
            present(alert, animated: true)
        }
    }
    
    func formattedTimeText(_ timeAsDouble: TimeInterval) -> String {
        let timeInterval = Int(timeAsDouble)
        let hour = timeInterval / 3600
        let minute = timeInterval % 3600 / 60
        let second = timeInterval % 3600 % 60
        return String(format: "%02d:%02d:%02d", arguments: [hour, minute, second])
    }
    
}

extension ViewController {
    func scheduleNotification(){
        let content = UNMutableNotificationContent()
        content.title = "Quiet Timer"
        content.body = "Time's up!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "empty_sound.mp3"))

        for i in 0...30 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remainingTime + Double(i), repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func removeNotification(){
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
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
        pvTimeData[component] = row
        selectedTime = TimeInterval(pvTimeData[0] * 60 * 60 + pvTimeData[1] * 60 + pvTimeData[2])
    }
    
}

