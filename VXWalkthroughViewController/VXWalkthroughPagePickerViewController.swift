//
//  VXWalkthroughPagePickerViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 10.12.19.
//

import Foundation
import UIKit

public class VXWalkthroughPagePickerViewController: VXWalkthroughPageViewController {
    @IBOutlet weak var previousButton: UIButton?
    @IBOutlet weak var nextButton: UIButton?
    @IBOutlet weak var actionButton: UIButton?

    var options = [[String: Any]]()
    var activeOption = 0 {
        didSet {
            if activeOption < self.options.count {
                let selectedItem = options[activeOption]
                if let i = selectedItem[VXWalkthroughField.image] as? String {
                    self.imageName = i
                }

                self.imageView?.layer.borderWidth = (self.selectedOption == selectedOption) ? 6 : 3

                self.previousButton?.isHidden = activeOption == 0
                self.nextButton?.isHidden = activeOption >= (options.count - 1)

                if activeOption == selectedOption {
                    if let t = self.item?[VXWalkthroughField.title] as? String, let st = selectedItem[VXWalkthroughField.title] as? String {
                        titleText = String(format: t, st)
                    }

                    self.actionButton?.isHidden = true
                } else {
                    if let t = selectedItem[VXWalkthroughField.title] as? String {
                        titleText = t
                    }
                    var isAvailable = false
                    if let t = selectedItem[VXWalkthroughField.isAvailable] as? Bool, t == true {
                        isAvailable = true
                    }
                    self.actionButton?.isHidden = false
                    self.enableActionButton(isAvailable)
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

        self.nextButton?.backgroundColor = self.actionButton?.backgroundColor
        self.previousButton?.backgroundColor = self.actionButton?.backgroundColor

        self.nextButton?.layer.borderColor = UIColor.white.cgColor
        self.previousButton?.layer.borderColor = UIColor.white.cgColor

        self.nextButton?.layer.borderWidth = 2.0
        self.previousButton?.layer.borderWidth = 2.0

        self.nextButton?.alpha = 1.0
        self.previousButton?.alpha = 1.0
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.actionButton?.layer.masksToBounds = true
        self.actionButton?.layer.cornerRadius = (self.actionButton?.frame.size.height ?? 44.0) * 0.25

    }

    func enableActionButton(_ isEnabled: Bool) {
        self.actionButton?.isEnabled = isEnabled
        self.actionButton?.alpha = isEnabled ? 1.0 : 0.5

    }

    func startAnimating() {
        self.enableActionButton(false)
        self.pulse(imageView, toSize: 0.8, withDuration: 2.0)
    }

    func stopAnimating() {
        self.enableActionButton(true)
        self.pulse(imageView, toSize: 0.8, withDuration: 0.0)
    }
    override public var item: [String : Any]? {
       didSet {
           super.item = item

            self.stopAnimating()

           if let item = item {
               if let t = item[VXWalkthroughField.error] as? String {
                    self.titleText = t
               } else if let t = item[VXWalkthroughField.success] as? String {
                    self.imageView?.layer.borderWidth = 6

                   self.titleText = t

                   // Assumber user denied request
                   self.actionButton?.isHidden = true
               } else {
                    self.enableActionButton(true)
                    self.selectedOption = 0
                    self.options = item[VXWalkthroughField.options] as? [[String: Any]] ??  [[String: Any]]()

                    if let pickerValue = item[VXWalkthroughField.pickerValue] as? String {
                        if let selected = options.firstIndex(where: { (dict) -> Bool in
                            dict[VXWalkthroughField.key] as? String == pickerValue
                        }) {
                            self.selectedOption = selected
                        }
                    }

                    self.activeOption = selectedOption

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
            if self.activeOption < self.options.count {
                self.selectedOption = self.activeOption
                let selectedItem = self.options[self.selectedOption]

                var itemResult: [String : Any]? = nil
                if let selected = selectedItem[VXWalkthroughField.key] {
                    itemResult = [
                        VXWalkthroughField.pickerValue: selected
                    ]
                }

                self.parentController?.delegate?.walkthroughActionButtonPressed?(self, item: itemResult)
            }
        }
    }

    @IBAction func nextClicked(_ sender: Any) {
        if self.activeOption < (self.options.count - 1) {
            self.activeOption += 1
        }
    }

    @IBAction func previousClicked(_ sender: Any) {
        if self.activeOption > 0 {
            self.activeOption -= 1
        }
    }

}
