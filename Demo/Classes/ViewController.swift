//
//  ViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 09.12.19.
//

import Foundation
import UIKit

class ViewController: UIViewController, VXWalkthroughViewControllerDelegate {
    override public func viewDidLoad() {
        super.viewDidLoad()

        if !VXWalkthroughViewController.walkthroughShown() {
            // this is to avoid timing issues
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                // show the walkthrough
                self.showWalkthrough()
            }
        }
    }

    @IBAction func present() {
        showWalkthrough()
    }

    func showWalkthrough() {
        let backgroundColor = UIColor(red: 167.0 / 255.0, green: 131.0 / 255.0, blue: 82.0 / 255.0, alpha: 1.0)

        // create the walkthough controller
        if let walkthrough = VXWalkthroughViewController.create(delegate: self, backgroundColor: backgroundColor) {
            // this is the default
            //    walkthrough.roundImages = YES;

            // this uses full screen images
            //    walkthrough.roundImages = NO;
            //    walkthrough.pageStoryboardID = @"WalkthroughPageFull";
            walkthrough.populate()

            var item = walkthrough.createItem("ITWALKTHROUGH_LOGIN", item: [
                VXWalkthroughViewController.storyboardID: VXWalkthroughPageLoginViewController.storyboardID,
                VXWalkthroughField.loginPrompt: NSLocalizedString("Email", comment: "Email"),
                VXWalkthroughField.passwordPrompt: NSLocalizedString("Password", comment: "Password"),
                VXWalkthroughField.placeholderValue: "xxxx-xxxx-xxxx"
            ])

            item?[VXWalkthroughField.image] = "walkthrough_0"
            item?[VXWalkthroughField.title] = "Long Title"
            item?[VXWalkthroughField.sort] = 1
            item?[VXWalkthroughField.isScanEnabled] = true

            walkthrough.items[VXWalkthroughField.key] = item
            // if let vc = self.createPageViewController("", item: ) {
            //    walkthrough.add(vc)
            // }

            // show it
            walkthrough.modalPresentationStyle = .fullScreen
            present(walkthrough, animated: true)
        }
    }

    func walkthroughCloseButtonPressed(_: Any?) {
        // delegate for handling close button
        dismiss(animated: true)
    }

    func walkthroughNextButtonPressed() {
        //
    }

    func walkthroughPrevButtonPressed() {
        //
    }

    func walkthroughPageDidChange(_: Int) {
        //
    }

    func walkthroughActionButtonPressed(_: Any?, item _: [String: Any]?) {
        //
    }

    override var shouldAutorotate: Bool {
        return true
    }
}
