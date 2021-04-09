//
//  DialViewController.swift
//  QuickStart
//
//  Copyright © 2020 Sendbird, Inc. All rights reserved.
//

import UIKit
import CallKit
import SendBirdCalls

class DialViewController: UIViewController, UITextFieldDelegate {
    // Profile
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    
    // Call
    @IBOutlet weak var calleeIdTextField: UITextField!
    @IBOutlet weak var voiceCallButton: UIButton!
    @IBOutlet weak var videoCallButton: UIButton!
    
    let indicator = UIActivityIndicatorView()
    
    // MARK: Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // To receive event when the credential has been updated
        CredentialManager.shared.addDelegate(self, forKey: "Dial")
        
        // Set up UI with current credential
        self.updateUI(with: UserDefaults.standard.credential)
        
        self.calleeIdTextField.delegate = self
        NotificationCenter.observeKeyboard(showAction: #selector(keyboardWillShow(_:)),
                                           hideAction: #selector(keyboardWillHide(_:)),
                                           target: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if var dataSource = segue.destination as? DirectCallDataSource, let call = sender as? DirectCall {
            dataSource.call = call
            dataSource.isDialing = true
        }
    }
}

// MARK: - User Interaction with SendBirdCall
extension DialViewController {
    @IBAction func didTapVoiceCall() {
        guard let calleeId = calleeIdTextField.text?.collapsed else {
            self.presentErrorAlert(message: DialErrors.emptyUserID.localizedDescription)
            return
        }
        self.voiceCallButton.isEnabled = false
        self.indicator.startLoading(on: self.view)
        
        // MARK: SendBirdCall.dial()
        let callOptions = CallOptions(isAudioEnabled: true)
        let dialParams = DialParams(calleeId: calleeId, isVideoCall: false, callOptions: callOptions, customItems: [:])

        SendBirdCall.dial(with: dialParams) { call, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.voiceCallButton.isEnabled = true
                self.indicator.stopLoading()
            }
            
            guard error == nil, let call = call else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.presentErrorAlert(message: DialErrors.voiceCallFailed(error: error).localizedDescription)
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.performSegue(withIdentifier: "voiceCall", sender: call)
            }
        }
    }
    
    @IBAction func didTapVideoCall() {
        guard let calleeId = calleeIdTextField.text?.collapsed else {
            self.presentErrorAlert(message: DialErrors.emptyUserID.localizedDescription)
            return
        }
        self.videoCallButton.isEnabled = false
        self.indicator.startLoading(on: self.view)
        
        // MARK: SendBirdCall.dial()
        let callOptions = CallOptions(isAudioEnabled: true, isVideoEnabled: true, useFrontCamera: true)
        let dialParams = DialParams(calleeId: calleeId, isVideoCall: true, callOptions: callOptions, customItems: [:])

        SendBirdCall.dial(with: dialParams) { call, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.videoCallButton.isEnabled = true
                self.indicator.stopLoading()
            }
            
            guard error == nil, let call = call else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.presentErrorAlert(message: DialErrors.videoCallFailed(error: error).localizedDescription)
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.performSegue(withIdentifier: "videoCall", sender: call)
            }
        }
    }
}

// MARK: - Credential Delegate
extension DialViewController: CredentialDelegate {
    func didUpdateCredential(_ credential: Credential?) {
        self.updateUI(with: credential)
    }
}

// MARK: - Setting Up UI
extension DialViewController {
    func updateUI(with credential: Credential?) {
        let profileURL = credential?.profileURL
        self.profileImageView.updateImage(urlString: profileURL)
        self.nicknameLabel.text = credential?.nickname.unwrap(with: "-")
        self.userIDLabel.text = "User ID: " + (credential?.userId ?? "-")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return textField.text?.collapsed != .none
    }
    
    // MARK: When Keyboard Show
    @objc
    func keyboardWillShow(_ notification: Notification) {
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut) {
            self.calleeIdTextField.layer.borderWidth = 1.0
            self.voiceCallButton.alpha = 0.0
            self.videoCallButton.alpha = 0.0
            
            self.view.layoutIfNeeded()
        }

        animator.startAnimation()
    }
    
    // MARK: When Keyboard Hide
    @objc
    func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.calleeIdTextField.layer.borderWidth = 0.0
            self.voiceCallButton.alpha = 1.0
            self.voiceCallButton.isEnabled = true
        
            self.videoCallButton.alpha = 1.0
            self.videoCallButton.isEnabled = true
            
            self.view.layoutIfNeeded()
        })
    }
}
