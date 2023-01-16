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
    
    var lbTime: UILabel!
    var lbGuideText: UILabel!
    var pvTime: UIPickerView!
    var btnStart: UIButton!
    var btnStop: UIButton!
    var btnPause: UIButton!
    var btnStack: UIStackView!
    var btnResume: UIButton!
    
    override func loadView() {
        super.loadView()
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: nil, using: sceneDidEnterBackgroundOrDidDisconnect(notification:))
        NotificationCenter.default.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: nil, using: sceneWillEnterForeground(notification:))
        NotificationCenter.default.addObserver(forName: UIScene.didDisconnectNotification, object: nil, queue: nil, using: sceneDidEnterBackgroundOrDidDisconnect(notification:))
        
        timer.updateHandler = timeUpdate
        
        pvTime.dataSource = self
        pvTime.delegate = self
        
        var labels = [Int:String]()
        labels[0] = "시"
        labels[1] = "분"
        labels[2] = "초"
        pvTime.setLabelForComponent(labels: labels, font: UIFont.systemFont(ofSize: 24))

    }

    func sceneDidEnterBackgroundOrDidDisconnect(notification: Notification){
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
                
                btnStack.addArrangedSubview(btnStop)
                btnStack.addArrangedSubview(btnResume)
            }
        }

        isAppFirstEnterForeground = false
    }

    
    
    func setupUI(){
        view.backgroundColor = UIColor(named: "backgroundColor")
        
        pvTime = UIPickerView()
        pvTime.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(pvTime)
        setPvTimeConstraint()
        
        btnStack = getBtnStack()
        view.addSubview(btnStack)
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        btnStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        btnStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -150).isActive = true
        btnStack.alignment = .center
        
        btnStart = RoundButton()
        btnStart.heightAnchor.constraint(equalToConstant: 120).isActive = true
        btnStart.widthAnchor.constraint(equalToConstant: 120).isActive = true
        
        btnStart.setTitle("시작", for: .normal)
        btnStart.setTitleColor(UIColor(named: "backgroundColor"), for: .normal)
        btnStart.backgroundColor = UIColor(named: "fontColor")
        btnStart.addTarget(self, action: #selector(btnStartTapped(_:)), for: .touchUpInside)
        btnStack.addArrangedSubview(btnStart)
        
        
        lbGuideText = UILabel()
        lbGuideText.text = "계속 집중하세요"
        lbGuideText.textColor = UIColor(named: "fontColor")
        lbGuideText.font = UIFont.systemFont(ofSize: 30)
        lbGuideText.translatesAutoresizingMaskIntoConstraints = false
        lbTime = getLbTime()
        
        btnStop = RoundButton()
        btnStop.heightAnchor.constraint(equalToConstant: 100).isActive = true
        btnStop.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btnStop.setTitle("종료", for: .normal)
        btnStop.backgroundColor = UIColor(named: "fontColor")
        btnStop.setTitleColor(UIColor(named: "backgroundColor"), for: .normal)
        btnStop.addTarget(self, action: #selector(btnStopTapped(_:)), for: .touchUpInside)
        btnStop.translatesAutoresizingMaskIntoConstraints = false

        btnPause = RoundButton()
        btnPause.heightAnchor.constraint(equalToConstant: 100).isActive = true
        btnPause.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btnPause.setTitle("일시정지", for: .normal)
        btnPause.backgroundColor = UIColor(named: "fontColor")
        btnPause.setTitleColor(UIColor(named: "backgroundColor"), for: .normal)
        btnPause.addTarget(self, action: #selector(btnPauseTapped(_:)), for: .touchUpInside)
        btnPause.translatesAutoresizingMaskIntoConstraints = false

        btnResume = RoundButton()
        btnResume.heightAnchor.constraint(equalToConstant: 100).isActive = true
        btnResume.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btnResume.setTitle("계속", for: .normal)
        btnResume.backgroundColor = UIColor(named: "fontColor")
        btnResume.setTitleColor(UIColor(named: "backgroundColor"), for: .normal)
        btnResume.addTarget(self, action: #selector(btnResumeTapped(_:)), for: .touchUpInside)
        btnResume.translatesAutoresizingMaskIntoConstraints = false

    }
    
    func setPvTimeSelection(){
        let hmsValue = getHMSValue(Int(timer.selectedTime))
        pvTime.selectRow(hmsValue[0], inComponent: 0, animated: false)
        pvTime.selectRow(hmsValue[1], inComponent: 1, animated: false)
        pvTime.selectRow(hmsValue[2], inComponent: 2, animated: false)
    }
    
    func setPvTimeConstraint(){
        pvTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70).isActive = true
        pvTime.widthAnchor.constraint(equalToConstant: 280).isActive = true
        pvTime.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
//        pvTime.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
//        pvTime.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
        pvTime.layoutIfNeeded()
    }
    
    func getBtnStack() -> UIStackView {
        let btnStack = UIStackView()
        btnStack.axis = .horizontal
        btnStack.distribution = .equalSpacing
        btnStack.spacing = 70
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        return btnStack
    }
   
    func getLbTime() -> UILabel {
        let lbTime = UILabel()
        lbTime.font = UIFont.systemFont(ofSize: 30.0)
        lbTime.textColor = UIColor(named: "fontColor")
        lbTime.translatesAutoresizingMaskIntoConstraints = false
        return lbTime
    }
    
    func setupTimerOnUI(){
        view.addSubview(lbTime)
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

//        pvTime.removeFromSuperview()
        view.addSubview(lbGuideText)
        lbGuideText.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        lbGuideText.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150).isActive = true
        
        view.addSubview(lbTime)
        lbTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        lbTime.topAnchor.constraint(equalTo: lbGuideText.bottomAnchor, constant: 50).isActive = true
        
        btnStack.removeAllSubviews()
        btnStack.addArrangedSubview(btnStop)
        btnStack.addArrangedSubview(btnPause)
        
        // TODO: transition 안됨
        UIView.transition(from: pvTime, to: lbGuideText!, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve)
        scheduleNotification()
    }
    
    @objc func btnStopTapped(_ sender: UIButton){
        timer.stop()
//        lbGuideText.removeFromSuperview()
//        lbTime.removeFromSuperview()
        
        view.addSubview(pvTime)
        setPvTimeConstraint()
        
        btnStack.removeAllSubviews()
        btnStack.addArrangedSubview(btnStart)
        
        UIView.transition(from: lbGuideText, to: pvTime, duration: TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
        
        removeNotification()
    }
    
    @objc func btnPauseTapped(_ sender: UIButton){
        timer.pause()
        UserDefaults.standard.set(timer.pausedAt, forKey: UserDefaultKey.PAUSED_AT)
        
        btnStack.removeAllSubviews()
        btnStack.addArrangedSubview(btnStop)
        btnStack.addArrangedSubview(btnResume)
        
        removeNotification()
    }
    
    @objc func btnResumeTapped(_ sender: UIButton) {
        timer.resume()
        scheduleNotification()
        
        btnStack.removeAllSubviews()
        btnStack.addArrangedSubview(btnStop)
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
                
                self.btnStack.removeAllSubviews()
                self.btnStack.addArrangedSubview(self.btnStart)
                
                UIView.transition(from: self.lbTime, to: self.pvTime, duration: self.TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
                
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
        
        // TODO: 개발 중에는 진동해제ㅎㅎ
//        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "empty_sound.mp3"))

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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        timer.selectedTime = TimeInterval((row + 1) * 60)
        let hour = pickerView.selectedRow(inComponent: 0)
        let minute = pickerView.selectedRow(inComponent: 1)
        let second = pickerView.selectedRow(inComponent: 2)
        timer.selectedTime = TimeInterval(hour * 60 * 60 + minute * 60 + second)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        if view != nil {
            return view!
        }
        
        let componentWidth = pvTime.frame.width / CGFloat(self.numberOfComponents(in: pvTime))
        let label = UIButton()
        label.setTitle(String(row), for: .normal)
        label.contentHorizontalAlignment = .trailing
        var configuration =  UIButton.Configuration.plain()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.foregroundColor = UIColor(named: "fontColor")
            outgoing.font = UIFont.systemFont(ofSize: 24)
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: componentWidth / 2 - 4)
        label.configuration = configuration
        label.isUserInteractionEnabled = false
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 80
    }
}


extension UIPickerView {
    func setLabelForComponent(labels: [Int:String], font: UIFont){
        let leftMargin:CGFloat = 7
        let paddingBetweenComponent:CGFloat = 4
        let componentWidth = self.frame.width / CGFloat(self.numberOfComponents)
        print(self.frame.width, self.numberOfComponents, componentWidth)
        let halfComponentWidth = componentWidth / 2
        let y = (self.frame.height / 2) - (font.pointSize / 2)
        
        for i in 0..<labels.count {
            if let labelText = labels[i] {
                let label = UILabel()
                label.frame = CGRect(x: (componentWidth * CGFloat(i)) + halfComponentWidth + leftMargin - paddingBetweenComponent * CGFloat(i), y: y, width: font.pointSize, height: font.pointSize)
                label.text = labelText
            
                label.font = UIFont.systemFont(ofSize: 24)
                label.textColor = UIColor(named: "fontColor")
                self.addSubview(label)
            }
        }

    }
}

extension UIStackView {
    func removeAllSubviews(){
        self.arrangedSubviews.forEach( { $0.removeFromSuperview() })
    }
}
