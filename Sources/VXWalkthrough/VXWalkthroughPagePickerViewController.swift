//
//  VXWalkthroughPagePickerViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 10.12.19.
//

import Foundation
import UIKit

public class VXWalkthroughPagePickerViewController: VXWalkthroughPageViewController {
    @IBOutlet var previousButton: UIButton?
    @IBOutlet var nextButton: UIButton?
    @IBOutlet var actionButton: UIButton?

    var options = [[String: Any]]()
    var activeOption = 0 {
        didSet {
            if activeOption < options.count {
                let selectedItem = options[activeOption]
                if let i = selectedItem[VXWalkthroughField.image] as? String {
                    imageName = i
                }

                imageView?.layer.borderWidth = (selectedOption == selectedOption) ? 6 : 3

                previousButton?.isHidden = activeOption == 0
                nextButton?.isHidden = activeOption >= (options.count - 1)

                if activeOption == selectedOption {
                    if let t = item?[VXWalkthroughField.title] as? String, let st = selectedItem[VXWalkthroughField.title] as? String {
                        titleText = String(format: t, st)
                    }

                    actionButton?.isHidden = true
                } else {
                    if let t = selectedItem[VXWalkthroughField.title] as? String {
                        titleText = t
                    }
                    var isAvailable = false
                    if let t = selectedItem[VXWalkthroughField.isAvailable] as? Bool, t {
                        isAvailable = true
                    }
                    actionButton?.isHidden = false
                    enableActionButton(isAvailable)
                }
            }
        }
    }

    var selectedOption: Int = 0

    override public class var storyboardID: String {
        return "WalkthroughPagePicker"
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        nextButton?.backgroundColor = actionButton?.backgroundColor
        previousButton?.backgroundColor = actionButton?.backgroundColor

        nextButton?.layer.borderColor = UIColor.white.cgColor
        previousButton?.layer.borderColor = UIColor.white.cgColor

        nextButton?.layer.borderWidth = 2.0
        previousButton?.layer.borderWidth = 2.0

        nextButton?.alpha = 1.0
        previousButton?.alpha = 1.0
    }

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

    override public var item: [String: Any]? {
        didSet {
            super.item = item

            stopAnimating()

            if let item = item {
                if let t = item[VXWalkthroughField.error] as? String {
                    titleText = t
                } else if let t = item[VXWalkthroughField.success] as? String {
                    imageView?.layer.borderWidth = 6

                    titleText = t

                    // Assumber user denied request
                    actionButton?.isHidden = true
                } else {
                    enableActionButton(true)
                    selectedOption = 0
                    options = item[VXWalkthroughField.options] as? [[String: Any]] ?? [[String: Any]]()

                    if let pickerValue = item[VXWalkthroughField.pickerValue] as? String {
                        if let selected = options.firstIndex(where: { dict -> Bool in
                            dict[VXWalkthroughField.key] as? String == pickerValue
                        }) {
                            selectedOption = selected
                        }
                    }

                    activeOption = selectedOption

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
            if self.activeOption < self.options.count {
                self.selectedOption = self.activeOption
                let selectedItem = self.options[self.selectedOption]

                var item: [String: Any] = self.item ?? [:]

                if let selected = selectedItem[VXWalkthroughField.key] {
                    item[VXWalkthroughField.pickerValue] = selected
                }

                self.parentController?.delegate?.walkthroughActionButtonPressed?(self, item: item)
            }
        }
    }

    @IBAction func nextClicked(_: Any) {
        if activeOption < (options.count - 1) {
            activeOption += 1
        }
    }

    @IBAction func previousClicked(_: Any) {
        if activeOption > 0 {
            activeOption -= 1
        }
    }
}
