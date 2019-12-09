//
//  VXWalkthroughPageViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 09.12.19.
//

import Foundation
import UIKit

enum VXWalkthroughAnimationType : Int {
    case linear = 0
    case curve = 1
    case zoom = 2
    case inOut = 3
}
class VXWalkthroughPageViewController: UIViewController, VXWalkthroughPage {
    var speed = CGPoint.zero
    var speedVariance = CGPoint.zero
    var animationType = VXWalkthroughAnimationType.inOut
    var animateAlpha = false
    var pageIndex = 0
    var imageName: String? {
        didSet {
            if let v = self.imageView {
                v.image = UIImage(named: imageName ?? "")
                v.isHidden = imageView.image == nil
            }
        }
    }
    var key: String?
    var item: [String : Any]? {
        didSet {
            if let item = item {
                if let t = item[VXWalkthroughViewController.kTitle] as? String {
                    self.titleText = t
                }
                if let t = item[VXWalkthroughViewController.kImage] as? String {
                    self.imageName = t
                }
            }

            if let v = self.imageView, self.roundImages {
                v.layer.borderWidth = 3.0
                v.layer.borderColor = UIColor.white.cgColor
                v.layer.shadowColor = UIColor.gray.cgColor
                v.layer.shadowRadius = 6.0
                v.layer.shadowOpacity = 0.5
            }
        }
    }
    var styles: [String : Any]?
    var roundImages = false
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    weak var parentController: VXWalkthroughViewController?
    var subsWeights = [CGPoint]()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    func setup() {
        // Edit these values using the Attribute inspector or modify directly the "User defined runtime attributes" in IB
        self.speed = CGPoint(x: 0.0, y: 0.0) // Note if you set this value via Attribute inspector it can only be an Integer (change it manually via User defined runtime attribute if you need a Float)
        self.speedVariance = CGPoint(x: 0.0, y: 0.0) // Note if you set this value via Attribute inspector it can only be an Integer (change it manually via User defined runtime attribute if you need a Float)
        self.animationType = .inOut
        self.animateAlpha = true
        self.roundImages = true
    }
    class var storyboardID: String {
        return "WalkthroughPage"
    }
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        view.layer.masksToBounds = true
        imageView?.isHidden = true
        titleView?.isHidden = true

        for _ in view.subviews {
            var speed = self.speed

            speed.x += speedVariance.x
            speed.y += speedVariance.y

            self.speed = speed
            subsWeights.append(self.speed)
        }
    }
    private var _titleText: String?
    var titleText: String? {
            get {
                _titleText
            }
            set(titleText) {
                titleView?.isHidden = false
                _titleText = titleText

                let fontSize = 24.0

        #if VX_SLASH

            if styles?.isEmpty ?? false {
                styles = [
                "$default": [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(fontSize)),
                NSAttributedString.Key.foregroundColor: UIColor.white
                ],
                "b": [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: CGFloat(fontSize))
                ],
                "em": [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: CGFloat(fontSize)),
                NSAttributedString.Key.foregroundColor: UIColor.white
                ]
                ]
            }
                let attributedString: NSAttributedString? = nil
            do {
            //    attributedString = try SLSMarkupParser.attributedString(withMarkup: self.titleText, style: styles)
            } catch {
                }
        #else
        let textAttributes = [
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(fontSize)),
                     NSAttributedString.Key.foregroundColor: UIColor.white
                 ]
                 let attributedString = NSAttributedString(string: _titleText ?? "", attributes: textAttributes)
#endif

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let alignedString = NSMutableAttributedString(attributedString: attributedString)

                alignedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: alignedString.length ))

            titleView?.attributedText = alignedString
            }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.roundImages {
            self.roundImageView(imageView)
        }
    }

    func roundImageView(_ imageView: UIImageView) {
        imageView.layer.cornerRadius = (imageView.frame.size.width ) / 2
        imageView.clipsToBounds = true

    }

    func walkthroughDidScroll(_ position: CGFloat, withOffset offset: CGFloat) {
        for i in 0..<subsWeights.count {
            // Perform Transition/Scale/Rotate animations
            switch animationType {
            case .linear:
                animationLinear(with: i, withOffset: offset)
            case .zoom:
                animationZoom(with: i, withOffset: offset)
            case .curve:
                animationCurve(with: i, withOffset: offset)
            case .inOut:
                animationInOut(with: i, withOffset: offset)
            }

            // Animate alpha
            if animateAlpha {
                animationAlpha(with: i, withOffset: offset)
            }
        }
    }

    func animationAlpha(with index: Int, withOffset offset: CGFloat) {
        var offset = offset
        let cView = view.subviews[index]

        if offset > 1.0 {
            offset = 1.0 + (1.0 - offset)
        }
        cView.alpha = offset
    }

    func animationCurve(with index: Int, withOffset offset: CGFloat) {
        var transform = CATransform3DIdentity
        let x = (1.0 - offset) * 10
        transform = CATransform3DTranslate(transform, (pow(x, 3) - (x * 25)) * subsWeights[index].x, (pow(x, 3) - (x * 20)) * subsWeights[index].y, 0)
        let cView = view.subviews[index]
        cView.layer.transform = transform
    }

    func animationZoom(with index: Int, withOffset offset: CGFloat) {
        var transform = CATransform3DIdentity

        var tmpOffset = offset
        if tmpOffset > 1.0 {
            tmpOffset = 1.0 + (1.0 - tmpOffset)
        }
        let scale = 1.0 - tmpOffset
        transform = CATransform3DScale(transform, 1 - scale, 1 - scale, 1.0)
        let cView = view.subviews[index]
        cView.layer.transform = transform
    }

    func animationLinear(with index: Int, withOffset offset: CGFloat) {
        var transform = CATransform3DIdentity
        let mx = (1.0 - offset) * 100
        transform = CATransform3DTranslate(transform, mx * subsWeights[index].x, mx * subsWeights[index].y, 0)
        let cView = view.subviews[index]
        cView.layer.transform = transform
    }

    func animationInOut(with index: Int, withOffset offset: CGFloat) {
        var transform = CATransform3DIdentity
        // CGFloat x = (1.0 - offset) * 20;
        var tmpOffset = offset
        if tmpOffset > 1.0 {
            tmpOffset = 1.0 + (1.0 - tmpOffset)
        }
        transform = CATransform3DTranslate(transform, (1.0 - tmpOffset) * subsWeights[index].x * 100, (1.0 - tmpOffset) * subsWeights[index].y * 100, 0)
        let cView = view.subviews[index]
        cView.layer.transform = transform
    }

    func isValidEmail(_ pEmail: String?, strict pStrictFilter: Bool) -> Bool {
        let stricterFilterString = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let laxString = ".+@.+\\.[A-Za-z]{2}[A-Za-z]*"

        let emailRegex = pStrictFilter ? stricterFilterString : laxString
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        return emailTest.evaluate(with: pEmail)
    }

    func pulse(_ view: UIView?, toSize value: Float, withDuration duration: Float) {
        view?.layer.removeAnimation(forKey: "pulse")

        if duration > 0.0 {
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = CFTimeInterval(duration)
            pulseAnimation.toValue = NSNumber(value: value)
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = Float.greatestFiniteMagnitude
            view?.layer.add(pulseAnimation, forKey: "pulse")
        }
    }

}
