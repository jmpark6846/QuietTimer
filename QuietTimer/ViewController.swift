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
    var timer = CountDownTimer()
    var isAppFirstEnterForeground = true
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

        NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: nil, using: sceneDidEnterBackground(notification:))
        NotificationCenter.default.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: nil, using: sceneWillEnterForeground(notification:))
        NotificationCenter.default.addObserver(forName: UIScene.didDisconnectNotification, object: nil, queue: nil, using: sceneDidDisconnectNotification(notification:))
        
        timer.updateHandler = timeUpdate
        
        pvTime.dataSource = self
        pvTime.delegate = self
    }

    func sceneDidEnterBackground(notification: Notification){
        let userDefaults = UserDefaults.standard
        timer.emptyTimer()

        userDefaults.set(timer.pausedAt, forKey: UserDefaultKey.PAUSED_AT)
        userDefaults.set(timer.status.rawValue, forKey: UserDefaultKey.STATUS)
        userDefaults.set(timer.endTime, forKey: UserDefaultKey.END_TIME)
        userDefaults.set(timer.selectedTime, forKey: UserDefaultKey.SELECTED_TIME)
    }

    func sceneWillEnterForeground(notification: Notification){
        let userDefaults = UserDefaults.standard

        timer.pausedAt = userDefaults.object(forKey: UserDefaultKey.PAUSED_AT) as? Date
        timer.selectedTime = userDefaults.double(forKey: UserDefaultKey.SELECTED_TIME)
        timer.endTime = userDefaults.double(forKey: UserDefaultKey.END_TIME)
        timer.status = TimerStatus.init(rawValue: userDefaults.integer(forKey: UserDefaultKey.STATUS))!
        
        setPvTimeSelection()
        
        
        if timer.status == .START {
            if timer.remainingTime > 0 {
                // start timer
                timer.setTimer()
                scheduleNotification()

                // make timer ui
                if isAppFirstEnterForeground {
                    pvTime.removeFromSuperview()
                    
                    view.addSubview(lbTime)
                    lbTime.text = formattedTimeText(timer.remainingTime)
                    setLbTimeConstraint()
                    
                    btnStart.removeFromSuperview()
                    btnStack.addArrangedSubview(btnStop)
                    btnStack.addArrangedSubview(btnPause)
                }
            }else{
                // stop timer
                timer.stop()
                removeNotification()

                // make ready ui
                if !isAppFirstEnterForeground {
                    lbTime.removeFromSuperview()

                    view.addSubview(pvTime)
                    setPvTimeConstraint()

                    btnStop.removeFromSuperview()
                    btnPause.removeFromSuperview()
                    btnResume.removeFromSuperview()
                    btnStack.addArrangedSubview(btnStart)
                }
            }
        }
        else if timer.status == .PAUSED {
            // disconnect 후 다시 들어온 경우(관련 플래그 확인) timer ui로 변경
            if isAppFirstEnterForeground {
                // make timer ui

                pvTime.removeFromSuperview()
                btnStart.removeFromSuperview()

                view.addSubview(lbTime)
                lbTime.text = formattedTimeText(timer.remainingTime)
                setLbTimeConstraint()
                
                btnStack.addArrangedSubview(btnStop)
                btnStack.addArrangedSubview(btnResume)
            }
        }

        isAppFirstEnterForeground = false
    }

    func sceneDidDisconnectNotification(notification: Notification){
        let userDefaults = UserDefaults.standard

        timer.emptyTimer()
        
//        print("dd ", pausedAt, selectedTime, endTime, status, timer, remainingTime)
        userDefaults.set(timer.pausedAt, forKey: UserDefaultKey.PAUSED_AT)
        userDefaults.set(timer.status.rawValue, forKey: UserDefaultKey.STATUS)
        userDefaults.set(timer.endTime, forKey: UserDefaultKey.END_TIME)
        userDefaults.set(timer.selectedTime, forKey: UserDefaultKey.SELECTED_TIME)
    }
    
    func setupUI(){
        pvTime = getPvTime()
        view.addSubview(pvTime)
        setPvTimeConstraint()
        
        lbTime = getLbTime()
        
        btnStart = UIButton()
        btnStart.setTitle("Start", for: .normal)
        btnStart.addTarget(self, action: #selector(btnStartTapped(_:)), for: .touchUpInside)
        btnStart.translatesAutoresizingMaskIntoConstraints = false
        
        btnStack = getBtnStack()
        btnStack.addArrangedSubview(btnStart)
        view.addSubview(btnStack)
        setBtnStackConstraint()
        
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
        
        btnResume = UIButton()
        btnResume.setTitle("Resume", for: .normal)
//        btnResume.setTitleColor(.black, for: .normal)
        btnResume.addTarget(self, action: #selector(btnResumeTapped(_:)), for: .touchUpInside)
    }
    
    func getPvTime() -> UIPickerView {
        let pvTime = UIPickerView()
        pvTime.translatesAutoresizingMaskIntoConstraints = false
        return pvTime
    }
    
    func setPvTimeConstraint() {
        pvTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pvTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
    }
    
    func setPvTimeSelection(){
        let hmsValue = getHMSValue(Int(timer.selectedTime))
        pvTime.selectRow(hmsValue[0], inComponent: 0, animated: false)
        pvTime.selectRow(hmsValue[1], inComponent: 1, animated: false)
        pvTime.selectRow(hmsValue[2], inComponent: 2, animated: false)
    }
    
    func getBtnStack() -> UIStackView {
        let btnStack = UIStackView()
        btnStack.axis = .horizontal
        btnStack.distribution = .fillEqually
        btnStack.spacing = 5.0
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        return btnStack
    }
    func setBtnStackConstraint() {
        btnStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        btnStack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func getLbTime() -> UILabel {
        let lbTime = UILabel()
        lbTime.font = UIFont.systemFont(ofSize: 30.0)
        lbTime.translatesAutoresizingMaskIntoConstraints = false
        return lbTime
    }
    
    func setLbTimeConstraint(){
        lbTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        lbTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
    }
    
    func setupTimerOnUI(){
        view.addSubview(lbTime)
        setLbTimeConstraint()
        lbTime.text = formattedTimeText(timer.remainingTime)
        
        btnStart.removeFromSuperview()
        btnStack.addArrangedSubview(btnStop)
        btnStack.addArrangedSubview(btnPause)
    }
        
    
    @objc func btnStartTapped(_ sender: UIButton) {
        if timer.selectedTime <= 0 {
            return
        }
        
        timer.start()
        
        lbTime.text = formattedTimeText(timer.remainingTime)
        view.addSubview(lbTime)
        setLbTimeConstraint()
        
        UIView.transition(from: pvTime, to: lbTime!, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve)
        
        btnStart.removeFromSuperview()
        btnStack.addArrangedSubview(btnStop)
        btnStack.addArrangedSubview(btnPause)
        
        scheduleNotification()
        
    }
    
    @objc func btnStopTapped(_ sender: UIButton){
        timer.stop()
        
        view.addSubview(pvTime)
        setPvTimeConstraint()
        UIView.transition(from: lbTime, to: pvTime, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
        
        btnStop.removeFromSuperview()
        btnPause.removeFromSuperview()
        btnResume.removeFromSuperview()
        btnStack.addArrangedSubview(btnStart)
        
        removeNotification()
    }
    
    @objc func btnPauseTapped(_ sender: UIButton){
        timer.pause()
        UserDefaults.standard.set(timer.pausedAt, forKey: UserDefaultKey.PAUSED_AT)
        
        btnPause.removeFromSuperview()
        btnStack.addArrangedSubview(btnStop)
        btnStack.addArrangedSubview(btnResume)
        
        removeNotification()
    }
    
    @objc func btnResumeTapped(_ sender: UIButton) {
        timer.resume()
        scheduleNotification()
        
        btnResume.removeFromSuperview()
        btnStack.addArrangedSubview(btnPause)
    }
    
    func timeUpdate(){
        guard let lbTime = lbTime else { return }
        lbTime.text = formattedTimeText(timer.remainingTime)
        
        if timer.remainingTime <= 0 {
            let alert = UIAlertController(title: "Alarm", message: "Time's up!", preferredStyle: .actionSheet)
            let action = UIAlertAction(title: "ok", style: .default) { action in
                self.view.addSubview(self.pvTime)
                self.setPvTimeConstraint()
                UIView.transition(from: self.lbTime, to: self.pvTime, duration: self.TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
                
                self.view.addSubview(self.btnStart)
                self.btnStop.removeFromSuperview()
                self.btnPause.removeFromSuperview()
                self.btnStack.addArrangedSubview(self.btnStart)
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
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timer.selectedTime + Double(i), repeats: false)
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
        timer.selectedTime = TimeInterval(pvTimeData[0] * 60 * 60 + pvTimeData[1] * 60 + pvTimeData[2])
    }
    
}

