//
//  ViewController.swift
//  projectG
//
//  Created by root0 on 2022/09/01.
//

import UIKit
import Then
import SnapKit
import GoogleSignIn
import Alamofire
import SwiftyJSON

import Speech

class ViewController: UIViewController {
    
    let mainView = UIView()
    
    let engineHow = UISegmentedControl(items: ["Naver", "Google"]).then { seg in
        let image = UIImage()
        seg.setTitleTextAttributes([.foregroundColor : UIColor.gray], for: .normal)
        seg.setTitleTextAttributes([.foregroundColor : UIColor.green,
                                    .font : UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .selected)
        seg.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "whatEngine")
        
        [UIControl.State.normal, .selected, .highlighted].forEach { state in
            seg.setBackgroundImage(image, for: state, barMetrics: .default)
        }
        seg.setDividerImage(image, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
    }
    
    let recordOpenBtn = UIButton().then {
        if #available(iOS 13.0, *) {
            $0.setImage(UIImage(systemName: "mic"), for: .normal)
            $0.setImage(UIImage(systemName: "mic.fill"), for: .selected)
            $0.tintColor = .red
        } else {
            $0.setTitle("녹음", for: .normal)
        }
        
    }
    
    let recordView = UIView().then {
        $0.backgroundColor = .gray
        $0.isHidden = true
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
    }
    
    let recordBtn = UIButton().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
    }
    
    
    private let speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? // 음성인식 요청을 처리
    private var recognitionTask: SFSpeechRecognitionTask? // 음성인식 요청 작업
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        speechRecognizer?.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }

    func initView() {
        addView()
        setConstraint()
    }
    
    private func addView() {
        view.addSubview(mainView)
        [engineHow, recordView, recordOpenBtn].forEach {
            view.addSubview($0)
        }
        
        [recordBtn].forEach {
            recordView.addSubview($0)
        }
        
        engineHow.addTarget(self, action: #selector(didChangeEngine(seg:)), for: .valueChanged)
        recordOpenBtn.addTarget(self, action: #selector(openRecording), for: .touchUpInside)
        recordBtn.addTarget(self, action: #selector(speechToText), for: .touchUpInside)
    }
    
    private func setConstraint() {
        mainView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        engineHow.snp.remakeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(view.snp.topMargin)
            $0.height.equalTo(50)
        }
        
        recordOpenBtn.snp.remakeConstraints {
            $0.width.height.equalTo(36)
            $0.trailing.equalTo(view.snp.trailingMargin)
            $0.bottom.equalTo(view.snp.bottomMargin)
        }
        recordView.snp.remakeConstraints {
            $0.leading.trailing.top.bottom.equalTo(recordOpenBtn)
        }
        
        
    }
    
    @objc func didChangeEngine(seg: UISegmentedControl) {
        let engine = seg.selectedSegmentIndex
        UserDefaults.standard.set(engine, forKey: "whatEngine")
        UserDefaults.standard.synchronize()
        print(engine)
    }
    
    @objc func openRecording() {
        // UI
        recordOpenBtn.isSelected.toggle()
        if recordOpenBtn.isSelected {
            recordView.isHidden = false
        }
        self.recordView.snp.remakeConstraints {
            if self.recordOpenBtn.isSelected {
                $0.leading.equalTo(self.mainView.snp.leadingMargin)
                $0.trailing.equalTo(self.mainView.snp.trailingMargin)
                $0.top.equalTo(self.mainView.snp.topMargin).offset(400)
                $0.bottom.equalTo(self.recordOpenBtn.snp.bottom)
            } else {
                $0.leading.trailing.top.bottom.equalTo(self.recordOpenBtn)
            }
        }

        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.recordView.isHidden = !self.recordOpenBtn.isSelected
        }
    }
    
    @objc func sendAction() {
        Papago.shared.translator(text: "korean") { text in
            print(text)
        }
        
    }
    
    @objc func authori() {
        print("adf")
        GIDSignIn.sharedInstance.signIn(with: GIDConfiguration(clientID: "780002601256-cutm2pjlacfkohi57uer6j73kkinbvbh.apps.googleusercontent.com"), presenting: self) { user, error in
            guard error == nil else { return }
            guard let user = user else { return }
//            UserDefaults.standard.set(user, forKey: "GIDUser")
            user.authentication.do { authen, error in
//                self.gtv3(token: authen?.accessToken)
                
            }
        }
        
    }
    
    @objc func speechToText() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordBtn.isEnabled = false
            recordBtn.setTitle("말해라", for: .normal)
        } else {
            startRecording()
            recordBtn.setTitle("말하다 멈춰!", for: .normal)
        }
    }
    
}

extension ViewController: SFSpeechRecognizerDelegate {
    func startRecording() {
        // 인식 작업이 실행중인지 먼저 확인하고 작업중이면 작업과 인식을 취소
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 오디오 녹음을 준비할 AVAudioSession을 준비, 세션의 범주를 녹음, 측정모드로 설정하고 활성화.
        // 예외 체크
        setAudioSession()
        
        // recognitionRequest 인스턴스화. Apple 서버에 오디오 데이터 전달하는데 사용
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
    }
    
    func setAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record)
            try audioSession.setMode(.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation) // 앱이 인터럽트가 끝나는 것을 알리고 재생을 재개할 것을 알림.
        } catch {
            print("오디오 세션 프로퍼티가 에러로 제대로 세팅되지 못함")
        }
    }
}

extension ViewController {
    
    
    
    func gtv3(token: String? = nil) {
        let text = "안녕하세요 오늘 출근했어요"
        let param: [String : Any] = [
            "contents" : text,
            "targetLanguageCode" : "en",
            "mimeType" : "text/plain"
        ]
        let header_gt: HTTPHeaders = [
            "Content-Type" : "application/x-www-form-urlencoded; charset=utf-8",
            "Authorization" : "Bearer \(token ?? "Default_Token")"
        ]
        
        AF.request("https://translate.googleapis.com/v3/projects/780002601256:translateText", method: .post, parameters: param, headers: header_gt).responseJSON { response in
            switch response.result {
            case .success(let data):
                let jsonData = JSON(data)
                print(jsonData["translations"][0]["translatedText"])
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
