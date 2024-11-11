//
//  VXWalkthroughPageActionViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 10.12.19.
//

import Foundation
import UIKit

public class VXWalkthroughPageActionViewController: VXWalkthroughPageViewController, Sendable {
    @IBOutlet var actionButton: UIButton?

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        actionButton?.layer.masksToBounds = true
        actionButton?.layer.cornerRadius = (actionButton?.frame.size.height ?? 44.0) * 0.25
    }

    func enableActionButton(_ isEnabled: Bool) {
        actionButton?.isEnabled = isEnabled
        actionButton?.alpha = isEnabled ? 1.0 : 0.5
    }

    func startAnimating() {
        enableActionButton(false)
        pulse(imageView, toSize: 0.8, withDuration: 2.0)
    }

    func stopAnimating() {
        enableActionButton(true)
        pulse(imageView, toSize: 0.8, withDuration: 0.0)
    }

    override public var item: [String: any Sendable]? {
        didSet {
            super.item = item

            stopAnimating()

            if let item = item {
				if let t = item[VXWalkthroughField.success] as? String {
					titleText = t

					// Assumber user denied request
					actionButton?.isHidden = true
				} else if let t = item[VXWalkthroughField.error] as? String {
						titleText = t

						// Assumber user denied request
						actionButton?.isHidden = true
                } else {
                    enableActionButton(true)

                    // setup fields
                    if let t = item[VXWalkthroughField.buttonTitle] as? String {
                        actionButton?.setTitle(t, for: .normal)
                    }
                }
            }
        }
    }

    @IBAction func actionClicked(_: Any) {
        UIView.animate(withDuration: 0.1, animations: {
            self.startAnimating()
        }) { _ in
            // start process
            let item: [String: any Sendable] = self.item ?? [:]
            self.parentController?.delegate?.walkthroughActionButtonPressed?(self, item: item)
        }
    }

    override public class var storyboardID: String {
        return "WalkthroughPageAction"
    }
}
