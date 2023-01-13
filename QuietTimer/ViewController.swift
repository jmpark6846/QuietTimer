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
    let TIMER_INTERVAL = 0.05
    
    var isAppFirstEnterForeground = true
    
    var status: TimerStatus = .READY
    var selectedTime: TimeInterval = 0.0
    var endTime: TimeInterval = 0.0
    var remainingTime: TimeInterval {
        if pausedAt != nil {
            return endTime - pausedAt!.timeIntervalSinceReferenceDate
        }
        
        let value = endTime - Date.timeIntervalSinceReferenceDate
        return value > 0 ? value : 0
    }

    
    var pausedAt: Date?
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
        
//        resetUserDefault()
//        let userDefaults = UserDefaults.standard
//        let pausedAt = userDefaults.object(forKey: UserDefaultKey.PAUSED_AT) as? Date
//        let selectedTime = userDefaults.double(forKey: UserDefaultKey.SELECTED_TIME)
//        let endTime = userDefaults.double(forKey: UserDefaultKey.END_TIME)
//        let status = TimerStatus.init(rawValue: userDefaults.integer(forKey: UserDefaultKey.STATUS))!
//
//        print("vdl ",pausedAt, selectedTime, endTime, status, timer, remainingTime)

        NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: nil, using: sceneDidEnterBackground(notification:))
        NotificationCenter.default.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: nil, using: sceneWillEnterForeground(notification:))
        NotificationCenter.default.addObserver(forName: UIScene.didDisconnectNotification, object: nil, queue: nil, using: sceneDidDisconnectNotification(notification:))

        pvTime.dataSource = self
        pvTime.delegate = self
    }
    
    func sceneDidEnterBackground(notification: Notification){
        let userDefaults = UserDefaults.standard
        if timer != nil && timer.isValid {
            timer.invalidate()
            timer = nil
        }
        print("deb ", pausedAt, selectedTime, endTime, status, timer, remainingTime)

        userDefaults.set(pausedAt, forKey: UserDefaultKey.PAUSED_AT)
        userDefaults.set(status.rawValue, forKey: UserDefaultKey.STATUS)
        userDefaults.set(endTime, forKey: UserDefaultKey.END_TIME)
        userDefaults.set(selectedTime, forKey: UserDefaultKey.SELECTED_TIME)
    }
    
    func sceneWillEnterForeground(notification: Notification){
        let userDefaults = UserDefaults.standard

        pausedAt = userDefaults.object(forKey: UserDefaultKey.PAUSED_AT) as? Date
        selectedTime = userDefaults.double(forKey: UserDefaultKey.SELECTED_TIME)
        endTime = userDefaults.double(forKey: UserDefaultKey.END_TIME)
        status = TimerStatus.init(rawValue: userDefaults.integer(forKey: UserDefaultKey.STATUS))!
        print("wef ", pausedAt, selectedTime, endTime, status, timer, remainingTime)
        switch status {
        case .READY:
            // user default에 있는 selectedtime으로 pvtime 초기화
            let hmsValue = getHMSValue(Int(selectedTime))
            pvTime.selectRow(hmsValue[0], inComponent: 0, animated: false)
            pvTime.selectRow(hmsValue[1], inComponent: 1, animated: false)
            pvTime.selectRow(hmsValue[2], inComponent: 2, animated: false)
        case .START:
            if remainingTime > 0 {
                // start timer
                timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timeUpdate), userInfo: nil, repeats: true)
                scheduleNotification()
                
                // make timer ui
                if isAppFirstEnterForeground {
                   setupTimerOnUI()
                    UIView.transition(from: pvTime, to: lbTime!, duration: TRANSITION_INTERVAL, options: .showHideTransitionViews)
                    UIView.transition(from: btnStart, to: btnStack, duration: TRANSITION_INTERVAL, options: .showHideTransitionViews)
                }
            }else{
                // stop timer
                endTime = 0
                if timer != nil && timer.isValid {
                    timer.invalidate()
                    timer = nil
                }
                status = .READY
                removeNotification()

                // make ready ui
                if isAppFirstEnterForeground {
                    let hmsValue = getHMSValue(Int(selectedTime))
                    pvTime.selectRow(hmsValue[0], inComponent: 0, animated: false)
                    pvTime.selectRow(hmsValue[1], inComponent: 1, animated: false)
                    pvTime.selectRow(hmsValue[2], inComponent: 2, animated: false)
                }else{
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
            }
            
        case .PAUSED:
            // disconnect 후 다시 들어온 경우(관련 플래그 확인) timer ui로 변경
            if isAppFirstEnterForeground {
                // make timer ui
                
                pvTime.removeFromSuperview()
                btnStart.removeFromSuperview()
                
                view.addSubview(lbTime)
                lbTime.text = formattedTimeText(remainingTime)
                lbTime.translatesAutoresizingMaskIntoConstraints = false
                lbTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                lbTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
                
                btnStack = getBtnStack()
                btnStack.addArrangedSubview(btnStop)
                btnStack.addArrangedSubview(btnResume)
                view.addSubview(btnStack)
                btnStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                btnStack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
                
            }
        }
        
        isAppFirstEnterForeground = false
    }
    
    func sceneDidDisconnectNotification(notification: Notification){
        let userDefaults = UserDefaults.standard

        if timer != nil && timer.isValid {
            timer.invalidate()
            timer = nil
        }
        print("dd ", pausedAt, selectedTime, endTime, status, timer, remainingTime)
        userDefaults.set(pausedAt, forKey: UserDefaultKey.PAUSED_AT)
        userDefaults.set(status.rawValue, forKey: UserDefaultKey.STATUS)
        userDefaults.set(endTime, forKey: UserDefaultKey.END_TIME)
        userDefaults.set(selectedTime, forKey: UserDefaultKey.SELECTED_TIME)
        
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
        
        btnStack = getBtnStack()
        btnStack.addArrangedSubview(btnStop)
        btnStack.addArrangedSubview(btnPause)
        
        btnResume = UIButton()
        btnResume.setTitle("Resume", for: .normal)
//        btnResume.setTitleColor(.black, for: .normal)
        btnResume.addTarget(self, action: #selector(btnResumeTapped(_:)), for: .touchUpInside)
    }
    
    func getBtnStack() -> UIStackView {
        let btnStack = UIStackView()
        btnStack.axis = .horizontal
        btnStack.distribution = .fillEqually
        btnStack.spacing = 5.0
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        return btnStack
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
        endTime = Date.timeIntervalSinceReferenceDate + selectedTime
        status = .START
        setupTimerOnUI()
        UIView.transition(from: pvTime, to: lbTime!, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve)
        UIView.transition(from: btnStart, to: btnStack, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve)
        
        timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timeUpdate), userInfo: nil, repeats: true)
        
        scheduleNotification()
        
    }
    
    @objc func btnStopTapped(_ sender: UIButton){
        status = .READY
        endTime = 0
        pausedAt = nil
        
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
    
    @objc func btnPauseTapped(_ sender: UIButton){
        status = .PAUSED
        pausedAt = Date()
        UserDefaults.standard.set(pausedAt, forKey: UserDefaultKey.PAUSED_AT)
        
        timer.invalidate()
        timer = nil
        removeNotification()
        
        btnPause.removeFromSuperview()
        btnStack.addArrangedSubview(btnResume)
    }
    
    @objc func btnResumeTapped(_ sender: UIButton) {
        if pausedAt == nil {
            return
        }
    
        status = .START
        endTime += Date.timeIntervalSinceReferenceDate - pausedAt!.timeIntervalSinceReferenceDate
        pausedAt = nil
        timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
        
        scheduleNotification()
        
        btnResume.removeFromSuperview()
        btnStack.addArrangedSubview(btnPause)
    }
    
    @objc func timeUpdate(){
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
        let timeInterval = Int(timeAsDouble.rounded())
        let hmsValue = getHMSValue(timeInterval)
        return String(format: "%02d:%02d:%02d", arguments: [hmsValue[0], hmsValue[1], hmsValue[2]])
    }
    
    func getHMSValue(_ timeInterval: Int) -> [Int] {
        let hour = timeInterval / 3600
        let minute = timeInterval % 3600 / 60
        let second = timeInterval % 3600 % 60
        return [hour, minute, second]
    }
    
    func resetUserDefault(){
        let userDefaults = UserDefaults.standard
        userDefaults.set(nil, forKey: UserDefaultKey.PAUSED_AT)
        userDefaults.set(0, forKey: UserDefaultKey.STATUS)
        userDefaults.set(0, forKey: UserDefaultKey.END_TIME)
        userDefaults.set(0, forKey: UserDefaultKey.SELECTED_TIME)
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

