//
//  CircularProgressBar.swift
//  QuietTimer
//
//  Created by 박준모 on 2023/01/18.
//

import UIKit

class CircularPrograssBar: UIView {
    let STROKE_START = "strokeStart"
    
    var duration: Double = 0.0
    var lastStrokeStart:CGFloat? = 0.0
    var trackLayer = CAShapeLayer()
    var progressBarLayer = CAShapeLayer()
    var animation: CAAnimation?
    
    var radius: CGFloat = 50.0
    var lineWidth: CGFloat = 5 {
        didSet{
            trackLayer.lineWidth = lineWidth
            progressBarLayer.lineWidth = lineWidth
        }
    }
    var progressTintColor: CGColor = UIColor.systemBlue.cgColor {
        didSet{
            progressBarLayer.strokeColor = progressTintColor
        }
    }
    var trackTintColor: CGColor = UIColor.lightGray.cgColor {
        didSet{
            trackLayer.strokeColor = trackTintColor
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func configure(){
        trackLayer.strokeColor = trackTintColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = lineWidth
        layer.addSublayer(trackLayer)
        
        progressBarLayer.strokeColor = progressTintColor
        progressBarLayer.fillColor = UIColor.clear.cgColor
        progressBarLayer.lineWidth = lineWidth
        progressBarLayer.lineCap = .round
        progressBarLayer.lineJoin = .round
        layer.addSublayer(progressBarLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnect), name: UIScene.didDisconnectNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didDisconnect() {
        // 씬 종료 되었을때: stroke start 정보를 UserDefaults에 저장
        guard let pointWhenDisconnected = getPresentationStrokeStart() else { return }
        let durationLeft = duration * (1 - Double(pointWhenDisconnected))
        
        UserDefaults.standard.set(durationLeft, forKey: "durationLeft")
        UserDefaults.standard.set(duration, forKey: "duration")
        UserDefaults.standard.set(Date(), forKey: "disconnectedAt")
    }
    
    @objc func didEnterBackground(){
        // 백그라운드로 진입: 현재 에니메이션 실행 중이면, 에니메이션을 변수에 저장
        animation = progressBarLayer.animation(forKey: STROKE_START)
    }
    
    @objc func willEnterForeground(){
        // 백그라운드 -> 포어그라운드 진입: 변수에 저장한 에니메이션 시작
        if let animation = animation {
            progressBarLayer.add(animation, forKey: STROKE_START)
        }
        // 씬 종료 -> 다시 실행: UserDefaults에 정보 불러와서 다시 들어오기전 시간만큼 더해준 다음 에니메이션 시작
        else {
            let duration = UserDefaults.standard.double(forKey: "duration")
            let durationLeft = UserDefaults.standard.double(forKey: "durationLeft")
            guard let disconnectedAt = UserDefaults.standard.object(forKey: "disconnectedAt") as? Date else { return }

            UserDefaults.standard.set(0, forKey: "duration")
            UserDefaults.standard.set(0, forKey: "durationLeft")
            UserDefaults.standard.set(nil, forKey: "disconnectedAt")
            
            let timeIntervalSinceDisconnected = Date.timeIntervalSinceReferenceDate - disconnectedAt.timeIntervalSinceReferenceDate
            let remainingTime = durationLeft - timeIntervalSinceDisconnected
            let pointToRestart = CGFloat(1 - remainingTime / duration)

            if  remainingTime > 0 {
                start(duration: remainingTime, from: pointToRestart)
            }
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: CGFloat(-90).radian(), endAngle: CGFloat(270).radian(), clockwise: true)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        trackLayer.path = path.cgPath
        trackLayer.position = center
        
        progressBarLayer.path = path.cgPath
        progressBarLayer.position = center
    }
    
    func start(duration: Double, from: Double = 0){
        if duration <= 0 {
            fatalError()
        }
        
        if progressBarLayer.timeOffset != 0.0 {
            fatalError("use resume() when paused")
        }
        self.duration = duration
        startAnimation(duration: duration, from: from)
    }

    func pause(){
        progressBarLayer.pause()
    }
    
    func stop(){
        progressBarLayer.strokeStart = 0
        progressBarLayer.removeAnimation(forKey: STROKE_START)
        progressBarLayer.stop()
    }
    func resume() {
        progressBarLayer.resume()
    }
    
    func startAnimation(duration: Double, from strokeStart: CGFloat){
        let animation = CABasicAnimation(keyPath: STROKE_START)
        animation.duration = duration
        animation.fromValue = strokeStart
        animation.toValue = 1.0
        animation.delegate = self
        animation.isRemovedOnCompletion = false 
        progressBarLayer.add(animation, forKey: STROKE_START)
    }
    
    func getPresentationStrokeStart() -> CGFloat? {
        return progressBarLayer.presentation()?.strokeStart
    }
}

extension CALayer {
    func pause() {
        let pausedTime : CFTimeInterval = self.convertTime(CACurrentMediaTime(), from: nil)
        self.speed = 0.0
        self.timeOffset = pausedTime
    }
    
    func resume(){
        let pausedTime = self.timeOffset
        self.speed = 1.0
        self.timeOffset = 0.0
        self.beginTime = 0.0
        let timeSincePause = self.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        self.beginTime = timeSincePause
    }
    
    func stop(){
        self.speed = 1.0
        self.timeOffset = 0.0
        self.beginTime = 0.0
    }
}



extension CircularPrograssBar: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            progressBarLayer.strokeStart = 1
        }
    }
}

extension CGFloat {
    func radian() -> CGFloat {
        return CGFloat(self * .pi / 180)//
    }
}
