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
    @IBOutlet weak var loginField: UITextField?
    @IBOutlet weak var passwordField: UITextField?
    @IBOutlet weak var loginLabel: UILabel?
    @IBOutlet weak var passwordLabel: UILabel?
    @IBOutlet weak var actionButton: UIButton?
    @IBOutlet weak var scanButton: UIButton?

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
        self.keyboardIsVisible = false

        self.loginField?.placeholder = "info@domain.com"
        self.loginField?.keyboardType = .emailAddress
        self.loginField?.autocapitalizationType = .none
        self.loginField?.autocorrectionType = .no
        self.loginField?.spellCheckingType = .no
        self.loginField?.returnKeyType = .next
        self.loginField?.delegate = self
        self.loginField?.textContentType = .emailAddress

        self.passwordField?.keyboardType = .asciiCapable
        self.passwordField?.autocorrectionType = .no
        self.passwordField?.spellCheckingType = .no
        self.passwordField?.returnKeyType = .done
        self.passwordField?.delegate = self
        self.passwordField?.textContentType = .password

        self.loginField?.addTarget(self, action: #selector(validateInput), for: .editingChanged)
        self.passwordField?.addTarget(self, action: #selector(validateInput), for: .editingChanged)
        self.passwordField?.addTarget(self, action: #selector(textFieldFinished(_:)), for: .editingDidEndOnExit)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        if let i = UIImage(named: "VXWalkthroughController.bundle/VXWalkthroughViewControllerScan@2x.png") {
            self.scanButton?.setImage(i, for: .normal)
        }

        self.enableActionButton(false)

        self.enableScanButton(false)

    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.actionButton?.layer.masksToBounds = true
        self.actionButton?.layer.cornerRadius = (self.actionButton?.frame.size.height ?? 44.0) * 0.25
        self.scanButton?.layer.masksToBounds = true
        self.scanButton?.layer.cornerRadius = (self.actionButton?.frame.size.height ?? 44.0) * 0.25

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

    func enableScanButton(_ isEnabled: Bool) {
        self.scanButton?.isHidden = !isEnabled
        self.scanButton?.isEnabled = isEnabled
        self.scanButton?.alpha = isEnabled ? 1.0 : 0.5
        self.actionTrailingMargin?.constant = isEnabled ? -(12.0 + (self.scanButton?.frame.size.width ?? 44.0)) : 0.0
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
        if let login = self.loginField?.text, !login.isEmpty {
            if let password = self.passwordField?.text, !password.isEmpty {
                if isValidEmail(login, strict: true) {
                    enableActionButton(true)
                }
            }
        }

        return true
    }
    override public var item: [String : Any]? {
        didSet {
            super.item = item

            if let item = item {
                if let t = item[VXWalkthroughViewController.kError] as? String {
                    stopAnimating()

                    self.titleText = t

                    // Assumber user denied request
                    self.enableActionButton(true)
                    if let t = item[VXWalkthroughViewController.kIsScanEnabled] as? String, !t.isEmpty {
                        self.enableScanButton(true)
                    }
                } else if let t = item[VXWalkthroughViewController.kSuccess] as? String {
                    stopAnimating()

                    self.titleText = t

                    // there was success, hide fields
                    self.actionButton?.isHidden = true

                    self.loginLabel?.isHidden = true
                    self.passwordLabel?.isHidden = true

                    self.loginField?.isHidden = true
                    self.passwordField?.isHidden = true
                    self.scanButton?.isHidden = true

                } else {
                    self.enableActionButton(true)
                    self.enableScanButton(false)

                    // setup fields
                    if let t = item[VXWalkthroughViewController.kButtonTitle] as? String {
                        self.actionButton?.setTitle(t, for: .normal)
                    }
                    // setup fields
                    if let t = item[VXWalkthroughViewController.kLoginPrompt] as? String {
                        self.loginLabel?.text = t
                    }
                    if let t = item[VXWalkthroughViewController.kPasswordPrompt] as? String {
                        self.passwordLabel?.text = t
                    }
                    if let t = item[VXWalkthroughViewController.kLoginValue] as? String {
                        self.loginField?.text = t
                    }
                    if let t = item[VXWalkthroughViewController.kPasswordValue] as? String {
                        self.passwordField?.text = t
                    }
                    if let t = item[VXWalkthroughViewController.kPlaceholderValue] as? String {
                        self.passwordField?.autocapitalizationType = .allCharacters
                        self.passwordField?.placeholder = t
                    }

                    #if canImport(QRCodeReader)
                    if let t = item[VXWalkthroughViewController.kIsScanEnabled] as? Bool, t == true {
                        enableScanButton(true)
                    }
                    #endif
                }

            }
        }
    }

    @IBAction func actionClicked(_ sender: Any) {
        self.loginField?.resignFirstResponder()
        self.passwordField?.resignFirstResponder()

        UIView.animate(withDuration: 0.1, animations: {
            self.startAnimating()
        }) { finished in
            // start process
            let item: [String: Any] = [
                VXWalkthroughViewController.kLoginValue: self.loginField?.text ?? "",
                VXWalkthroughViewController.kPasswordValue: self.passwordField?.text ?? ""
            ]
            self.parentController?.delegate?.walkthroughActionButtonPressed?(self, item: item)
        }
    }
    #if canImport(QRCodeReader)
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)

            // Configure the view controller (optional)
            $0.startScanningAtLoad    = true
            $0.showTorchButton        = true
            $0.showSwitchCameraButton = true
            $0.showCancelButton       = true
            $0.cancelButtonTitle      = NSLocalizedString("cancel", comment: "cancel")

            // $0.showOverlayView        = true
            //$0.rectOfInterest         = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        }
        return QRCodeReaderViewController(builder: builder)
    }()
    @IBAction func scanClicked(_ sender: Any) {
        if let supportsQR = try? QRCodeReader.supportsMetadataObjectTypes([.qr]), supportsQR {
            readerVC.completionBlock = { (result: QRCodeReaderResult?) in
                if let qrCode = result?.value {
                    print("\(qrCode)")
                    //https://truck.app.link/truck?voucher=JOPJ-OI6I-VWKO&teacher=L025&flavor=ch_truck_premium

                    if qrCode.hasPrefix("http") || qrCode.hasPrefix("https") {
                        let urlComponents = URLComponents(string: qrCode)
                        let queryItems = urlComponents?.queryItems
                        for item in queryItems ?? [] {
                            print("\(item)")
                            if (item.name == "voucher") {
                                self.passwordField?.text = item.value
                            } else if (item.name == "teacher") {
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
                }
            }

            readerVC.modalPresentationStyle = .fullScreen

            self.parentController?.present(readerVC, animated: true, completion: nil)
        }
    }
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
      reader.stopScanning()

      dismiss(animated: true, completion: nil)
    }
    #endif
}
