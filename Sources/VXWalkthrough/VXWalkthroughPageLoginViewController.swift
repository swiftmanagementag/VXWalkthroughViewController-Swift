//
//  VXWalkthroughPageLoginViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 10.12.19.
//

import Foundation
import UIKit
#if canImport(QRCodeReader)
    import QRCodeReader
#endif

public class VXWalkthroughPageLoginViewController: VXWalkthroughPageViewController, UITextFieldDelegate {
    @IBOutlet var loginField: UITextField?
    @IBOutlet var passwordField: UITextField?
    @IBOutlet var loginLabel: UILabel?
    @IBOutlet var passwordLabel: UILabel?
    @IBOutlet var actionButton: UIButton?
    @IBOutlet var scanButton: UIButton?

    @IBOutlet var actionTrailingMargin: NSLayoutConstraint?

    var keyboardIsVisible = false

    override public class var storyboardID: String {
        return "WalkthroughPageLogin"
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        keyboardIsVisible = false

        loginField?.placeholder = "info@domain.com"
        loginField?.keyboardType = .emailAddress
        loginField?.autocapitalizationType = .none
        loginField?.autocorrectionType = .no
        loginField?.spellCheckingType = .no
        loginField?.returnKeyType = .next
        loginField?.delegate = self
        loginField?.textContentType = .emailAddress
        loginField?.tag = 1
        passwordField?.keyboardType = .asciiCapable
        passwordField?.autocorrectionType = .no
        passwordField?.spellCheckingType = .no
        passwordField?.returnKeyType = .done
        passwordField?.delegate = self
        passwordField?.textContentType = .password
        loginField?.tag = 2

        loginField?.addTarget(self, action: #selector(validateInput), for: .editingChanged)
        passwordField?.addTarget(self, action: #selector(validateInput), for: .editingChanged)
        passwordField?.addTarget(self, action: #selector(textFieldFinished(_:)), for: .editingDidEndOnExit)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        let b = Bundle(for: VXWalkthroughViewController.self)

        if let i = UIImage(named: "VXWalkthroughViewControllerScan@2x.png", in: b, with: nil) {
            scanButton?.setImage(i, for: .normal)
        }

        enableActionButton(false)

        enableScanButton(false)
    }
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        actionButton?.layer.masksToBounds = true
        actionButton?.layer.cornerRadius = (actionButton?.frame.size.height ?? 44.0) * 0.25
        scanButton?.layer.masksToBounds = true
        scanButton?.layer.cornerRadius = (actionButton?.frame.size.height ?? 44.0) * 0.25
    }

    @IBAction func textFieldFinished(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField === loginField) {
            passwordField?.becomeFirstResponder()
        } else {
            self.actionClicked(textField)
        }

        return true
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

    func enableScanButton(_ isEnabled: Bool) {
        scanButton?.isHidden = !isEnabled
        scanButton?.isEnabled = isEnabled
        scanButton?.alpha = isEnabled ? 1.0 : 0.5
        actionTrailingMargin?.constant = isEnabled ? +(12.0 + (scanButton?.frame.size.width ?? 44.0)) : 0.0
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
            f.origin.y = 0
            //f.origin.y += kbSize.height - 45.0
            self.view.frame = f
        })
        keyboardIsVisible = false
    }

    @objc func validateInput() -> Bool {
        // enable button if input valid
        enableActionButton(false)
        if let login = loginField?.text, !login.isEmpty {
            if let password = passwordField?.text, !password.isEmpty {
                if isValidEmail(login, strict: true) {
                    enableActionButton(true)
                }
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

                    // Assumber user denied request
                    enableActionButton(true)
                    if let t = item[VXWalkthroughField.isScanEnabled] as? String, !t.isEmpty {
                        enableScanButton(true)
                    }
                } else if let t = item[VXWalkthroughField.success] as? String {
                    titleText = t

                    // there was success, hide fields
                    actionButton?.isHidden = true

                    loginLabel?.isHidden = true
                    passwordLabel?.isHidden = true

                    loginField?.isHidden = true
                    passwordField?.isHidden = true
                    scanButton?.isHidden = true

                } else {
                    enableActionButton(true)
                    enableScanButton(false)

                    // setup fields
                    if let t = item[VXWalkthroughField.buttonTitle] as? String {
                        actionButton?.setTitle(t, for: .normal)
                    }
                    // setup fields
                    if let t = item[VXWalkthroughField.loginPrompt] as? String {
                        loginLabel?.text = t
                    }
                    if let t = item[VXWalkthroughField.passwordPrompt] as? String {
                        passwordLabel?.text = t
                    }
                    if let t = item[VXWalkthroughField.loginValue] as? String {
                        loginField?.text = t
                    }
                    if let t = item[VXWalkthroughField.passwordValue] as? String {
                        passwordField?.text = t
                    }
                    if let t = item[VXWalkthroughField.placeholderValue] as? String {
                        passwordField?.autocapitalizationType = .allCharacters
                        passwordField?.placeholder = t
                    }

                    #if canImport(QRCodeReader)
                    if let t = item[VXWalkthroughField.isScanEnabled] as? String, !t.isEmpty {
                        enableScanButton(true)
                    }
                    #endif
                }
            }
        }
    }

    @IBAction func actionClicked(_: Any) {
        loginField?.resignFirstResponder()
        passwordField?.resignFirstResponder()

        UIView.animate(withDuration: 0.1, animations: {
            self.startAnimating()
        }) { _ in
            // start process
            var item: [String: Any] = self.item ?? [:]

            item[VXWalkthroughField.loginValue] = self.loginField?.text ?? ""
            item[VXWalkthroughField.passwordValue] = self.passwordField?.text ?? ""
            self.parentController?.delegate?.walkthroughActionButtonPressed?(self, item: item)
        }
    }

    #if canImport(QRCodeReader)
        lazy var readerVC: QRCodeReaderViewController = {
            let builder = QRCodeReaderViewControllerBuilder {
                $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)

                // Configure the view controller (optional)
                $0.startScanningAtLoad = true
                $0.showTorchButton = true
                $0.showSwitchCameraButton = true
                $0.showCancelButton = true
                $0.cancelButtonTitle = NSLocalizedString("cancel", comment: "cancel")

                // $0.showOverlayView        = true
                // $0.rectOfInterest         = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
            }
            return QRCodeReaderViewController(builder: builder)
        }()

        @IBAction func scanClicked(_: Any) {
            if let supportsQR = try? QRCodeReader.supportsMetadataObjectTypes([.qr]), supportsQR {
                readerVC.completionBlock = { (result: QRCodeReaderResult?) in
                    if let qrCode = result?.value {
                        print("\(qrCode)")
                        // https://truck.app.link/truck?voucher=JOPJ-OI6I-VWKO&teacher=L025&flavor=ch_truck_premium

                        if qrCode.hasPrefix("http") || qrCode.hasPrefix("https") {
                            let urlComponents = URLComponents(string: qrCode)
                            let queryItems = urlComponents?.queryItems
                            for item in queryItems ?? [] {
                                print("\(item)")
                                if item.name == "voucher" {
                                    self.passwordField?.text = item.value
                                } else if item.name == "teacher" {
                                    UserDefaults.standard.set(item.value, forKey: "teacher_preference")
                                    UserDefaults.standard.synchronize()
                                }
                            }
                        } else {
                            self.passwordField?.text = qrCode
                        }
                        self.readerVC.dismiss(animated: true) {
                            _ = self.validateInput()
                        }
                    } else {
                        self.readerVC.dismiss(animated: true, completion: nil)
                    }
                }

                readerVC.modalPresentationStyle = .fullScreen

                parentController?.present(readerVC, animated: true, completion: nil)
            }
        }

        func readerDidCancel(_ reader: QRCodeReaderViewController) {
            reader.stopScanning()
            reader.dismiss(animated: true, completion: nil)

            // dismiss(animated: true, completion: nil)
        }
    #endif
}
