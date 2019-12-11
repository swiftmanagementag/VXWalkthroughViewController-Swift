//
//  VXWalkthroughPageActionViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 10.12.19.
//

import Foundation
import UIKit

public class VXWalkthroughPageActionViewController: VXWalkthroughPageViewController {
    @IBOutlet weak var actionButton: UIButton?

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.actionButton?.layer.masksToBounds = true
        self.actionButton?.layer.cornerRadius = (actionButton?.frame.size.height ?? 44.0) * 0.25

    }

    func enableActionButton(_ isEnabled: Bool) {
        actionButton?.isEnabled = isEnabled
        actionButton?.alpha = isEnabled ? 1.0 : 0.5

    }

    func startAnimating() {
        self.enableActionButton(false)
        self.pulse(self.imageView, toSize: 0.8, withDuration: 2.0)
    }

    func stopAnimating() {
        self.enableActionButton(true)
        self.pulse(imageView, toSize: 0.8, withDuration: 0.0)
    }
    override public var item: [String : Any]? {
        didSet {
            super.item = item

            if let item = item {
                if let t = item[VXWalkthroughField.error] as? String {
                    stopAnimating()

                    self.titleText = t

                    // Assumber user denied request
                    self.actionButton?.isHidden = true
                } else if let t = item[VXWalkthroughField.success] as? String {
                    stopAnimating()

                    self.titleText = t

                    // Assumber user denied request
                    self.actionButton?.isHidden = true
                } else {
                    self.enableActionButton(true)

                    // setup fields
                    if let t = item[VXWalkthroughField.buttonTitle] as? String {
                        self.actionButton?.setTitle(t, for: .normal)
                    }
                }

            }
        }
    }
    @IBAction func actionClicked(_ sender: Any) {
        UIView.animate(withDuration: 0.1, animations: {
            self.startAnimating()
        }) { finished in
            // start process
            let item: [String : Any] = [:]
            self.parentController?.delegate?.walkthroughActionButtonPressed?(self, item: item)
        }
    }

    override public class var storyboardID: String {
        return "WalkthroughPageAction"
    }
}
