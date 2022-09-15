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
import RxSwift
import RxCocoa

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
        $0.setTitle("말하기 시작", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.setTitle("말 못한다", for: .disabled)
        $0.setTitle("말 하는중", for: .selected)
    }
    
    let translatedTextView = UITextView().then {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.green.cgColor
        $0.layer.cornerRadius = 16
        $0.layer.masksToBounds = true
        $0.isEditable = false
        $0.contentInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    }
    
    let speechScriptTextView = UITextView().then {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.white.cgColor
        $0.layer.cornerRadius = 16
        $0.layer.masksToBounds = true
        $0.backgroundColor = .clear
        $0.isEditable = false
        $0.contentInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    }

    private let speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? // 음성인식 요청을 처리
    private var recognitionTask: SFSpeechRecognitionTask? // 음성인식 요청 작업
    private let audioEngine = AVAudioEngine()
    
    private let viewModel = STTViewModel()
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
//        speechRecognizer?.delegate = self
        
        previousGIDSign()
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .notDetermined:
                self.recordBtn.setTitle("음성인식 권한체크", for: .normal)
            case .denied:
                self.recordBtn.setTitle("권한 거부", for: .normal)
            case .restricted:
                self.recordBtn.setTitle("권한 제한", for: .normal)
            case .authorized:
                print(status)
            @unknown default:
                fatalError()
            }
        }
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
        [engineHow, translatedTextView, recordView, recordOpenBtn].forEach {
            view.addSubview($0)
        }
        
        [recordBtn, speechScriptTextView].forEach {
            recordView.addSubview($0)
        }
        
        bindViewModel()
        engineHow.addTarget(self, action: #selector(didChangeEngine(seg:)), for: .valueChanged)
//        recordOpenBtn.addTarget(self, action: #selector(openRecording), for: .touchUpInside)
//        recordBtn.addTarget(self, action: #selector(speechToText), for: .touchUpInside)
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
        
        translatedTextView.snp.remakeConstraints {
            $0.leading.equalTo(view.snp.leadingMargin)
            $0.trailing.equalTo(view.snp.trailingMargin)
            $0.top.equalTo(engineHow.snp.bottomMargin)
            $0.bottom.equalTo(view.snp.bottomMargin)
        }
        
        recordOpenBtn.snp.remakeConstraints {
            $0.width.height.equalTo(36)
            $0.trailing.equalTo(view.snp.trailingMargin)
            $0.bottom.equalTo(view.snp.bottomMargin)
        }
        recordView.snp.remakeConstraints {
            $0.leading.trailing.top.bottom.equalTo(recordOpenBtn)
        }
        
        recordBtn.snp.remakeConstraints {
            $0.bottom.equalToSuperview().offset(-16)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(150)
        }
        
        speechScriptTextView.snp.remakeConstraints {
            $0.top.equalTo(recordView.snp.topMargin)
            $0.leading.equalTo(recordView.snp.leadingMargin)
            $0.trailing.equalTo(recordView.snp.trailingMargin)
            $0.bottom.equalTo(recordBtn.snp.top).offset(-8)
        }
        
    }
    
    func remakeRecordView() {
        if recordOpenBtn.isSelected {
            recordView.isHidden = false
        }
        recordView.snp.remakeConstraints {
            if recordOpenBtn.isSelected {
                $0.leading.equalTo(view.snp.leadingMargin)
                $0.trailing.equalTo(view.snp.trailingMargin)
                $0.top.equalTo(mainView.snp.topMargin).offset(400)
                $0.bottom.equalTo(recordOpenBtn.snp.bottom)
            } else {
                $0.leading.trailing.top.bottom.equalTo(recordOpenBtn)
            }
        }
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.recordView.isHidden = !self.recordOpenBtn.isSelected
        }
    }
    
    private func bindViewModel() {
        let input = STTViewModel.Inputs.init(recordOpenBtn_tap: recordOpenBtn.rx.tap.map { _ in }, recordBtn_tap: recordBtn.rx.tap.map { _ in })
        let output = viewModel.transform(input: input)
        
        output.openRecording
            .drive { [weak self] _ in
                guard let self = self else { return }
                self.recordOpenBtn.isSelected.toggle()
                self.remakeRecordView()
            }
            .disposed(by: bag)
        
        output.recordAction
            .drive { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.speech.speechAction()
            }
            .disposed(by: bag)
        
        viewModel.speechScript
            .map { $0 }
            .drive { [weak self] spscript in
                guard let self = self else { return }
                self.speechScriptTextView.text = spscript
            }
            .disposed(by: bag)
        
        viewModel.recordBtnTitle
            .drive { [weak self] str in
                guard let self = self else { return }
                self.recordBtn.setTitle(str, for: .normal)
            }
            .disposed(by: bag)
    }
    
    @objc func didChangeEngine(seg: UISegmentedControl) {
        let engine = seg.selectedSegmentIndex
        UserDefaults.standard.set(engine, forKey: "whatEngine")
        UserDefaults.standard.synchronize()
        print(engine)
        if engine == 0 { // naver
            
        } else if engine == 1 { // google
            authori()
        }
    }
    
//    @objc func openRecording() {
//        // UI
//        recordOpenBtn.isSelected.toggle()
//        if recordOpenBtn.isSelected {
//            recordView.isHidden = false
//        }
//        self.recordView.snp.remakeConstraints {
//            if self.recordOpenBtn.isSelected {
//                $0.leading.equalTo(self.view.snp.leadingMargin)
//                $0.trailing.equalTo(self.view.snp.trailingMargin)
//                $0.top.equalTo(self.mainView.snp.topMargin).offset(400)
//                $0.bottom.equalTo(self.recordOpenBtn.snp.bottom)
//            } else {
//                $0.leading.trailing.top.bottom.equalTo(self.recordOpenBtn)
//            }
//        }
//
//        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut) {
//            self.view.layoutIfNeeded()
//        } completion: { _ in
//            self.recordView.isHidden = !self.recordOpenBtn.isSelected
//        }
//    }
    
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
                UserDefaults.standard.set(authen?.accessToken, forKey: "userGID_AccessToken")
                
                print(user.grantedScopes)
                GIDSignIn.sharedInstance.addScopes(["https://www.googleapis.com/auth/cloud-translation", "https://www.googleapis.com/auth/cloud-platform"], presenting: self)
                print(user.grantedScopes)
                
            }
        }
        
    }
    
//    @objc func speechToText() {
//        if audioEngine.isRunning {
//            audioEngine.stop()
//            recognitionRequest?.endAudio()
//            recordBtn.isEnabled = false
//
//        } else {
//            startRecording()
//        }
//    }
    
}

//extension ViewController: SFSpeechRecognizerDelegate {
//    func startRecording() {
//        // 인식 작업이 실행중인지 먼저 확인하고 작업중이면 작업과 인식을 취소
//        if recognitionTask != nil {
//            /// kAFAssistantErrorDomain code=203 : SFSpeechRecognitionTask 를 완료하거나 취소할 때 결과를 감지 할 수 없는 경우
////            recognitionTask?.cancel()
//            recognitionTask?.finish()
//            recognitionTask = nil
//        }
//
//        // 오디오 녹음을 준비할 AVAudioSession을 준비, 세션의 범주를 녹음, 측정모드로 설정하고 활성화.
//        // 예외 체크
//        setAudioSession()
//
//        // recognitionRequest 인스턴스화. Apple 서버에 오디오 데이터 전달하는데 사용
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//
//        // AudioEngine(장치)에 녹음 할 오디오 입력이 있는지 확인, 없으면 치명적 에러 나옴
//        // -> 오디오 엔진은 inputNode에 처음 액세스할 때 싱글톤을 생성해서 nil일수가 없으다...
//        let inputNode = audioEngine.inputNode
//        // recognitionRequest 객체가 인스턴스화 되고 nil이 아닌지 확인
//        guard let recognitionRequest = recognitionRequest else {
//            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
//        }
//
//        // 사용자의 음성인식 - 부분적인 결과 보고하도록 프로퍼티 설정
//        recognitionRequest.shouldReportPartialResults = true
//
//        // 인식을 시작하려면 speechRecognizer의 recognitionTask 메소드를 호출해야 한다.
//        // 요청에 따라 음성발화를 인식. 부분결과보고shouldReportPartialResults가 true이면 Result 핸들러가 호출
//        // 부분적인 결과를 반복하고 마지막에 최종 결과 or 오류 반환
//        let gidToken = UserDefaults.standard.string(forKey: "userGID_AccessToken") ?? "DEFAULT"
//        print(gidToken)
//        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
//            // 인식이 최종인지 확인 bool
//            var isFinal = false
//            // 결과가 nil이 아닌경우 결과의 최상의 텍스트로 설정, 최종결과이면 isFinal 업데이트
//            if result != nil {
//                print(result!.bestTranscription.formattedString)
//                self.speechScriptTextView.text = result!.bestTranscription.formattedString
//                self.gtv3(token: gidToken, text: result!.bestTranscription.formattedString)
//                isFinal = result!.isFinal
//            }
//
//            if error != nil || isFinal {
//                self.audioEngine.stop()
//                inputNode.removeTap(onBus: 0)
//                self.recognitionRequest = nil
//                self.recognitionTask = nil
//                self.recordBtn.isEnabled = true
//                self.recordBtn.setTitle("말하기 시작", for: .normal)
//            }
//        })
//        // recognitionRequest에 오디오 입력을 추가.
//        // 인식 작업을 시작한 후에는 오디오 입력을 추가해도 괜찮습니다.
//        // 오디오 프레임 워크는 오디오 입력이 추가되는 즉시 인식을 시작합니다.
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
//            self.recognitionRequest?.append(buffer)
//        }
//
//        // 아직 음성인식 안끝났을 수도
//        audioEngine.prepare()
//        do {
//            try audioEngine.start()
//        } catch {
//            print("audioEngine couldn't start because of an \(error.localizedDescription)")
//        }
//
//        recordBtn.setTitle("말 멈추기", for: .normal)
//    }
//
//    func setAudioSession() {
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.record)
//            try audioSession.setMode(.measurement)
//            try audioSession.setActive(true, options: .notifyOthersOnDeactivation) // 앱이 인터럽트가 끝나는 것을 알리고 재생을 재개할 것을 알림.
//        } catch {
//            print("오디오 세션 프로퍼티가 에러로 제대로 세팅되지 못함")
//        }
//
//    }
//}

extension ViewController {
    
    func previousGIDSign() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
                // show the app's signed-out state
                print("no user")
            } else {
                // sign in state
                print("step signin")
                print(user?.grantedScopes)
                
            }
        }
    }
    
    func gtv3(token: String? = nil, text: String? = nil) {
        let text = text ?? "안녕하세요 오늘 출근했어요"
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
                print(jsonData)
                self.translatedTextView.text = jsonData["translations"][0]["translatedText"].stringValue
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
