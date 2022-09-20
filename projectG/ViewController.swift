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
    
    private let viewModel = STTViewModel()
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
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
        
        viewModel.translatedText
            .drive { [weak self] text in
                guard let self = self else { return }
                self.translatedTextView.text = text
            }
            .disposed(by: bag)
    }
    
    @objc func didChangeEngine(seg: UISegmentedControl) {
        let engine = seg.selectedSegmentIndex
        UserDefaults.standard.set(engine, forKey: "whatEngine")
        UserDefaults.standard.synchronize()
        print(engine)
        if engine == 0 { // naver
            sendAction()
        } else if engine == 1 { // google
            authori()
        }
    }
    
    @objc func sendAction() {
//        Papago.shared.translator(text: "korean") { text in
//            print(text)
//        }
        view.addSubview(MyMarkers(frame: self.view.frame))
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
    
}

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
    
    
}
