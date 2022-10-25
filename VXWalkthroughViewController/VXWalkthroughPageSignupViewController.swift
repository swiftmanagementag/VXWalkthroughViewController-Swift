//
//  VXWalkthroughPageSignupViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 10.12.19.
//

import Foundation
import UIKit

public class VXWalkthroughPageSignupViewController: VXWalkthroughPageViewController, UITextFieldDelegate {
    @IBOutlet var emailField: UITextField?
    @IBOutlet var emailLabel: UILabel?
    @IBOutlet var messageLabel: UILabel?
    @IBOutlet var actionButton: UIButton?

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
        keyboardIsVisible = false

        emailField?.placeholder = "info@domain.com"
        emailField?.keyboardType = .emailAddress
        emailField?.autocapitalizationType = .none
        emailField?.autocorrectionType = .no
        emailField?.spellCheckingType = .no
        emailField?.returnKeyType = .next
        emailField?.delegate = self
        emailField?.textContentType = .emailAddress
        emailField?.addTarget(self, action: #selector(validateInput), for: .editingChanged)
        emailField?.addTarget(self, action: #selector(textFieldFinished(_:)), for: .editingDidEndOnExit)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        actionButton?.layer.masksToBounds = true
        actionButton?.layer.cornerRadius = (actionButton?.frame.size.height ?? 44.0) * 0.25
    }

    @IBAction func textFieldFinished(_ sender: UITextField) {
        sender.resignFirstResponder()
    }

    func startAnimating() {
        enableActionButton(false)
        pulse(imageView, toSize: 0.8, withDuration: 2.0)
    }

    func stopAnimating() {
        enableActionButton(true)
        pulse(imageView, toSize: 0.8, withDuration: 0.0)
    }

    func enableActionButton(_ isEnabled: Bool) {
        actionButton?.isEnabled = isEnabled
        actionButton?.alpha = isEnabled ? 1.0 : 0.5
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
        if let email = emailField?.text, !email.isEmpty {
            if isValidEmail(email, strict: true) {
                enableActionButton(true)
            }
        }

        return true
    }

    override public var item: [String: Any]? {
        didSet {
            super.item = item

            stopAnimating()

            if let item = item {
                if let t = item[VXWalkthroughField.error] as? String {
                    titleText = t

                    enableActionButton(true)
                } else if let t = item[VXWalkthroughField.success] as? String {
                    titleText = t

                    // there was success, hide fields
                    actionButton?.isHidden = true
                    emailField?.isHidden = true
                    emailLabel?.isHidden = true
                } else {
                    enableActionButton(true)

                    // setup fields
                    if let t = item[VXWalkthroughField.buttonTitle] as? String {
                        actionButton?.setTitle(t, for: .normal)
                    }
                    // setup fields
                    if let t = item[VXWalkthroughField.emailPrompt] as? String {
                        emailLabel?.text = t
                    }
                    if let t = item[VXWalkthroughField.emailValue] as? String {
                        emailField?.text = t
                    }
                    if let t = item[VXWalkthroughField.placeholderValue] as? String {
                        emailField?.placeholder = t
                    }
                }
            }
        }
    }

    @IBAction func actionClicked(_: Any) {
        emailField?.resignFirstResponder()

        UIView.animate(withDuration: 0.1, animations: {
            self.startAnimating()
        }) { _ in
            // start process
            let item: [String: Any] = [
                VXWalkthroughField.emailValue: self.emailField?.text ?? ""
            ]
            self.parentController?.delegate?.walkthroughActionButtonPressed?(self, item: item)
        }
    }
}
