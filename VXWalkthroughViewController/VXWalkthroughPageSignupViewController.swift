//
//  VXWalkthroughPageSignupViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 10.12.19.
//

import Foundation
import UIKit

public class VXWalkthroughPageSignupViewController: VXWalkthroughPageViewController, UITextFieldDelegate {
    @IBOutlet weak var emailField: UITextField?
    @IBOutlet weak var emailLabel: UILabel?
    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var actionButton: UIButton?

    var keyboardIsVisible = false

    override public class var storyboardID: String {
        return "WalkthroughPageSignup"
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.keyboardIsVisible = false

        self.emailField?.placeholder = "info@domain.com"
        self.emailField?.keyboardType = .emailAddress
        self.emailField?.autocapitalizationType = .none
        self.emailField?.autocorrectionType = .no
        self.emailField?.spellCheckingType = .no
        self.emailField?.returnKeyType = .next
        self.emailField?.delegate = self
        self.emailField?.textContentType = .emailAddress
        self.emailField?.addTarget(self, action: #selector(validateInput), for: .editingChanged)
        self.emailField?.addTarget(self, action: #selector(textFieldFinished(_:)), for: .editingDidEndOnExit)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.actionButton?.layer.masksToBounds = true
        self.actionButton?.layer.cornerRadius = (self.actionButton?.frame.size.height ?? 44.0) * 0.25

    }

    @IBAction func textFieldFinished(_ sender: UITextField) {
        sender.resignFirstResponder()
    }

    func startAnimating() {
        self.enableActionButton(false)
        self.pulse(imageView, toSize: 0.8, withDuration: 2.0)
    }

    func stopAnimating() {
        self.enableActionButton(true)
        self.pulse(imageView, toSize: 0.8, withDuration: 0.0)
    }

    func enableActionButton(_ isEnabled: Bool) {
        self.actionButton?.isEnabled = isEnabled
        self.actionButton?.alpha = isEnabled ? 1.0 : 0.5
    }

    @objc func keyboardWillShow(_ notification: Notification?) {
        if keyboardIsVisible {
            return
        }

        let info = notification?.userInfo
        let kbSize = (info?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size

        UIView.animate(withDuration: 0.2, animations: {
            var f = self.view.frame
            f.origin.y -= kbSize.height
            self.view.frame = f
        })
        keyboardIsVisible = true
    }

    @objc func keyboardWillHide(_ notification: Notification?) {
        if !keyboardIsVisible {
            return
        }

        let info = notification?.userInfo
        let kbSize = (info?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size

        UIView.animate(withDuration: 0.2, animations: {
            var f = self.view.frame
            f.origin.y += kbSize.height
            self.view.frame = f
        })
        keyboardIsVisible = false
    }
    @objc func validateInput() -> Bool {
        // enable button if input valid
        enableActionButton(false)
        if let email = self.emailField?.text, !email.isEmpty {
            if isValidEmail(email, strict: true) {
                enableActionButton(true)
            }
        }

        return true
    }
    override public var item: [String : Any]? {
        didSet {
            super.item = item

            if let item = item {
                if let t = item[VXWalkthroughField.error] as? String {
                    stopAnimating()

                    self.titleText = t

                    self.enableActionButton(true)
                } else if let t = item[VXWalkthroughField.success] as? String {
                    stopAnimating()

                    self.titleText = t

                    // there was success, hide fields
                    self.actionButton?.isHidden = true
                    self.emailField?.isHidden = true
                    self.emailLabel?.isHidden = true
                } else {
                    self.enableActionButton(true)

                    // setup fields
                    if let t = item[VXWalkthroughField.buttonTitle] as? String {
                        self.actionButton?.setTitle(t, for: .normal)
                    }
                    // setup fields
                    if let t = item[VXWalkthroughField.emailPrompt] as? String {
                        self.emailLabel?.text = t
                    }
                    if let t = item[VXWalkthroughField.emailValue] as? String {
                        self.emailField?.text = t
                    }
                    if let t = item[VXWalkthroughField.placeholderValue] as? String {
                        self.emailField?.placeholder = t
                    }
                }

            }
        }
    }

    @IBAction func actionClicked(_ sender: Any) {
        self.emailField?.resignFirstResponder()

        UIView.animate(withDuration: 0.1, animations: {
            self.startAnimating()
        }) { finished in
            // start process
            let item: [String: Any] = [
                VXWalkthroughField.emailValue: self.emailField?.text ?? ""
            ]
            self.parentController?.delegate?.walkthroughActionButtonPressed?(self, item: item)
        }
    }
}
