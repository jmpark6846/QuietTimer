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
    var isFirstActivationAfterAppLaunch = true
    
    var lbTime: UILabel!
    var lbGuideText: UILabel!
    var pvTime: UIPickerView!
    var btnStart: UIButton!
    var btnStop: UIButton!
    var btnPause: UIButton!
    var btnStack: UIStackView!
    var btnResume: UIButton!
    var progressBar = CircularPrograssBar()
    var progressBarStrokeStart: CGFloat = 0.0
    
    override func loadView() {
        super.loadView()
        
    }
    override func viewDidLayoutSubviews() {
        setupPickerViewLabel()
        lbGuideText.bottomAnchor.constraint(equalTo: progressBar.topAnchor, constant: progressBar.bounds.height / 2 - 15).isActive = true
        lbTime.topAnchor.constraint(equalTo: progressBar.topAnchor, constant: progressBar.bounds.height / 2 + 15).isActive = true
    }

    func setupPickerViewLabel(){
        var labels = [Int:String]()
        labels[0] = "시"
        labels[1] = "분"
        labels[2] = "초"
        pvTime.setLabelForComponent(labels: labels, font: UIFont.systemFont(ofSize: 24))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
//        resetUserDefaultData()
        // TODO: 타이머 실행 중에 다시 빌드하면 상태 저장 안된 상태로 종료되고 새 빌드로 시작(앱 터미네이트 시점인가?)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveDataToUserDefaults), name: UIScene.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveDataToUserDefaults), name: UIScene.didDisconnectNotification, object: nil)
    
        timer.updateHandler = timeUpdate
        pvTime.dataSource = self
        pvTime.delegate = self
    }

    @objc func saveDataToUserDefaults(){
        let strokeStart: CGFloat = progressBar.getPresentationStrokeStart() ?? 0
        timer.emptyTimer()
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(timer.pausedAt, forKey: UserDefaultKey.PAUSED_AT)
        userDefaults.set(timer.status.rawValue, forKey: UserDefaultKey.STATUS)
        userDefaults.set(timer.endTime, forKey: UserDefaultKey.END_TIME)
        userDefaults.set(timer.selectedTime, forKey: UserDefaultKey.SELECTED_TIME)
        userDefaults.set(strokeStart, forKey: UserDefaultKey.STROKE_START)
    }
    
    @objc func willEnterForeground(){
        let userDefaults = UserDefaults.standard

        timer.pausedAt = userDefaults.object(forKey: UserDefaultKey.PAUSED_AT) as? Date
        timer.selectedTime = userDefaults.double(forKey: UserDefaultKey.SELECTED_TIME)
        timer.endTime = userDefaults.double(forKey: UserDefaultKey.END_TIME)
        timer.status = TimerStatus.init(rawValue: userDefaults.integer(forKey: UserDefaultKey.STATUS))!
        progressBarStrokeStart = CGFloat(userDefaults.float(forKey: UserDefaultKey.STROKE_START))
        userDefaults.set(nil, forKey: UserDefaultKey.PAUSED_AT)
        userDefaults.set(0, forKey: UserDefaultKey.STATUS)
        userDefaults.set(0, forKey: UserDefaultKey.END_TIME)
        userDefaults.set(0, forKey: UserDefaultKey.SELECTED_TIME)
        userDefaults.set(0, forKey: UserDefaultKey.STROKE_START)
        
        setPvTimeSelection()
        
        if timer.status == .START {
            if timer.remainingTime > 0 {
                // start timer
                timer.setTimer()
                scheduleNotification()
            
                // make timer ui
                if isFirstActivationAfterAppLaunch {
                    setupTimerUI()
                }
                
            }else{
                // stop timer
                timer.stop()
                removeNotification()
                
                // make selection ui
                if !isFirstActivationAfterAppLaunch {
                    setupTimeSelectionUI()
//                    progressBar.stop()
                }
            }
        }
        else if timer.status == .PAUSED {
            // disconnect 후 다시 들어온 경우(관련 플래그 확인) timer ui로 변경
            if isFirstActivationAfterAppLaunch {
                // make timer ui
                setupTimerUI()
                btnResume.isHidden = false
                btnPause.isHidden = true
            }
        }

        isFirstActivationAfterAppLaunch = false
    }

    func setupUI(){
        view.backgroundColor = UIColor(named: "backgroundColor")
        
        pvTime = UIPickerView()
        pvTime.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(pvTime)
        pvTime.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70).isActive = true
//        pvTime.widthAnchor.constraint(equalToConstant: 280).isActive = true
        pvTime.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        pvTime.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
        pvTime.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true

        btnStart = RoundButton()
        view.addSubview(btnStart)
        btnStart.heightAnchor.constraint(equalToConstant: 120).isActive = true
        btnStart.widthAnchor.constraint(equalToConstant: 120).isActive = true
        btnStart.setTitle("시작", for: .normal)
        btnStart.setTitleColor(UIColor(named: "backgroundColor"), for: .normal)
        btnStart.backgroundColor = UIColor(named: "fontColor")
        btnStart.addTarget(self, action: #selector(btnStartTapped(_:)), for: .touchUpInside)
        btnStart.translatesAutoresizingMaskIntoConstraints = false
        btnStart.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        btnStart.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -150).isActive = true
        
        btnStop = RoundButton()
        view.addSubview(btnStop)
        btnStop.heightAnchor.constraint(equalToConstant: 100).isActive = true
        btnStop.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btnStop.setTitle("종료", for: .normal)
        btnStop.backgroundColor = UIColor(named: "fontColor")
        btnStop.setTitleColor(UIColor(named: "backgroundColor"), for: .normal)
        btnStop.addTarget(self, action: #selector(btnStopTapped(_:)), for: .touchUpInside)
        btnStop.translatesAutoresizingMaskIntoConstraints = false
        btnStop.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 50).isActive = true
        btnStop.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -150).isActive = true

        btnPause = RoundButton()
        view.addSubview(btnPause)
        btnPause.heightAnchor.constraint(equalToConstant: 100).isActive = true
        btnPause.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btnPause.setTitle("일시정지", for: .normal)
        btnPause.backgroundColor = UIColor(named: "fontColor")
        btnPause.setTitleColor(UIColor(named: "backgroundColor"), for: .normal)
        btnPause.addTarget(self, action: #selector(btnPauseTapped(_:)), for: .touchUpInside)
        btnPause.translatesAutoresizingMaskIntoConstraints = false
        btnPause.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -50).isActive = true
        btnPause.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -150).isActive = true

        btnResume = RoundButton()
        view.addSubview(btnResume)
        btnResume.heightAnchor.constraint(equalToConstant: 100).isActive = true
        btnResume.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btnResume.setTitle("계속", for: .normal)
        btnResume.backgroundColor = UIColor(named: "fontColor")
        btnResume.setTitleColor(UIColor(named: "backgroundColor"), for: .normal)
        btnResume.addTarget(self, action: #selector(btnResumeTapped(_:)), for: .touchUpInside)
        btnResume.translatesAutoresizingMaskIntoConstraints = false
        btnResume.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -50).isActive = true
        btnResume.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -150).isActive = true

        progressBar.backgroundColor = .clear
        progressBar.radius = view.bounds.width / 2 - 50
        progressBar.progressTintColor = UIColor(named: "systemPink")?.cgColor ?? UIColor.systemBlue.cgColor
        progressBar.trackTintColor = UIColor.lightGray.cgColor
        view.addSubview(progressBar)
        progressBar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30).isActive = true
        progressBar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        progressBar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
//                progressBar.widthAnchor.constraint(equalToConstant: 200).isActive = true
        progressBar.heightAnchor.constraint(equalTo: progressBar.widthAnchor).isActive = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        
        lbGuideText = UILabel()
        lbGuideText.text = "계속 집중하세요"
        lbGuideText.textColor = UIColor(named: "fontColor")
        lbGuideText.font = UIFont.systemFont(ofSize: 30)
        lbGuideText.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lbGuideText)
        lbGuideText.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        lbTime = UILabel()
        lbTime.font = UIFont.systemFont(ofSize: 30.0)
        lbTime.textColor = UIColor(named: "fontColor")
        lbTime.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lbTime)
        lbTime.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        // 최초 UI 세팅
        setupTimeSelectionUI()
    }
    
    func setPvTimeSelection(){
        let hmsValue = getHMSValue(Int(timer.selectedTime))
        pvTime.selectRow(hmsValue[0], inComponent: 0, animated: false)
        pvTime.selectRow(hmsValue[1], inComponent: 1, animated: false)
        pvTime.selectRow(hmsValue[2], inComponent: 2, animated: false)
    }
    
    func setupTimeSelectionUI(){
        pvTime.isHidden = false
        btnStart.isHidden = false
        
        lbGuideText.isHidden = true
        lbTime.isHidden = true
        progressBar.isHidden = true
        
        btnStop.isHidden = true
        btnResume.isHidden = true
        btnPause.isHidden = true
    }
    
    func setupTimerUI(){
        pvTime.isHidden = true
        btnStart.isHidden = true
        
        progressBar.isHidden = false
        lbGuideText.isHidden = false
        lbTime.isHidden = false
        lbTime.text = formattedTimeText(timer.remainingTime)
        
        btnStop.isHidden = false
        btnResume.isHidden = true
        btnPause.isHidden = false
    }
        
    
    @objc func btnStartTapped(_ sender: UIButton) {
        if timer.selectedTime <= 0 {
            return
        }
        
        timer.start()
        setupTimerUI()
        progressBar.start(duration: timer.remainingTime)

        
        // TODO: Transition
//        UIView.transition(with: pvTime, duration: 0.1, options: .transitionCrossDissolve) {
//            self.pvTime.alpha = 0
//        } completion: {_ in }

        scheduleNotification()
    }
    
    @objc func btnPauseTapped(_ sender: UIButton){
        timer.pause()
        progressBar.pause()
        
        btnStop.isHidden = false
        btnPause.isHidden = true
        btnResume.isHidden = false
    
        removeNotification()
    }
    
    @objc func btnResumeTapped(_ sender: UIButton) {
        timer.resume()
        scheduleNotification()
        
        progressBar.resume()
        
        btnStop.isHidden = false
        btnPause.isHidden = false
        btnResume.isHidden = true
    }
    
    @objc func btnStopTapped(_ sender: UIButton){
        timer.stop()
        progressBar.stop()
        
        setupTimeSelectionUI()
        removeNotification()
    }
    

    func timeUpdate(){
        guard let lbTime = lbTime else { return }
        lbTime.text = formattedTimeText(timer.remainingTime)

        if timer.remainingTime <= 0 {
            let alert = UIAlertController(title: "Alarm", message: "Time's up!", preferredStyle: .actionSheet)
            let action = UIAlertAction(title: "ok", style: .default) { action in
                self.setupTimeSelectionUI()
//                UIView.transition(from: self.lbTime, to: self.pvTime, duration: self.TRANSITION_INTERVAL, options: .transitionCrossDissolve, completion: nil)
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
    
    func printUserDefaultData(){
        let userDefaults = UserDefaults.standard
        let pausedAt = userDefaults.object(forKey: UserDefaultKey.PAUSED_AT) as? Date
        let selectedTime = userDefaults.double(forKey: UserDefaultKey.SELECTED_TIME)
        let endTime = userDefaults.double(forKey: UserDefaultKey.END_TIME)
        let status = TimerStatus.init(rawValue: userDefaults.integer(forKey: UserDefaultKey.STATUS))!
        print("pausedAt: \(String(describing: pausedAt))")
        print("selectedTime: \(selectedTime)")
        print("endTime: \(endTime)")
        print("stauts: \(status)")
        
    }
    func resetUserDefaultData(){
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
        let componentWidth = self.bounds.width / CGFloat(self.numberOfComponents)
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
