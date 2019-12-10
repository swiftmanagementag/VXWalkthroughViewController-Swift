//
//  VXWalkthroughPageViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 09.12.19.
//

import Foundation
import UIKit

public enum VXWalkthroughAnimationType : Int {
    case linear = 0
    case curve = 1
    case zoom = 2
    case inOut = 3
}
public class VXWalkthroughPageViewController: UIViewController, VXWalkthroughPage {
    var animationType = VXWalkthroughAnimationType.inOut
    var subviewsSpeed = [CGPoint]()
     // Array of views' tags that should not be animated during the scroll/transition
    var notAnimatableViews:[Int] = []

    var speed = CGPoint(x: 1.0, y: 0.5)
    var speedVariance = CGPoint(x: 0.8, y:0.5)
    var animateAlpha = true
    var roundImages = true

    var pageIndex = 0
    var imageName: String? {
        didSet {
            if let v = self.imageView {
                v.image = UIImage(named: imageName ?? "")
                v.isHidden = imageView.image == nil
            }
        }
    }
    public var key: String?
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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    weak var parentController: VXWalkthroughViewController?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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

        for v in view.subviews {
            speed.x += speedVariance.x
            speed.y += speedVariance.y
            if !notAnimatableViews.contains(v.tag) {
                subviewsSpeed.append(speed)
            }
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

                if let t = titleText {
                    let fontSize = 24.0

                    let regularAttributes = [
                         NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(fontSize)),
                         NSAttributedString.Key.foregroundColor: UIColor.white
                    ]
                    let boldAttributes = [
                         NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: CGFloat(fontSize)),
                         NSAttributedString.Key.foregroundColor: UIColor.white
                    ]

                    let attributedString = NSMutableAttributedString(string: t, attributes: regularAttributes)

                    // add bold handling
                    if t.contains("*") {
                        var shift = 0 // number of characters removed so far
                        let pattern = "(\\*)(.*?)(\\*)"

                        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                            regex.enumerateMatches(in: t, options: [], range: NSMakeRange(0, t.count)) { result, flags, stop in

                                if let r = result {
                                    var r1 = r.range(at: 1) // Location of the leading delimiter
                                    var r2 = r.range(at: 2) // Location of the string between the delimiters
                                    var r3 = r.range(at: 3) // Location of the trailing delimiter
                                    // Adjust locations according to the string modifications:
                                    r1.location -= shift
                                    r2.location -= shift
                                    r3.location -= shift

                                    attributedString.addAttributes(boldAttributes, range: r2)

                                    attributedString.mutableString.deleteCharacters(in: r3)
                                    attributedString.mutableString.deleteCharacters(in: r1)
                                    // Update offset:
                                    shift += r1.length + r3.length
                                }
                            }
                        }

                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .center

                        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length ))
                    }
                    titleView?.attributedText = attributedString
                } else {
                    titleView?.text = nil
                    titleView?.attributedText = nil
                }
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

    public func walkthroughDidScroll(_ position: CGFloat, withOffset offset: CGFloat) {
        for i in 0..<subviewsSpeed.count {
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
        transform = CATransform3DTranslate(transform, (pow(x,3) - (x * 25)) * subviewsSpeed[index].x, (pow(x,3) - (x * 20)) * subviewsSpeed[index].y, 0 )
        applyTransform(index, transform: transform)
    }

    func animationZoom(with index: Int, withOffset offset: CGFloat) {
        var transform = CATransform3DIdentity

        var tmpOffset = offset
        if tmpOffset > 1.0 {
            tmpOffset = 1.0 + (1.0 - tmpOffset)
        }
        let scale = 1.0 - tmpOffset
        transform = CATransform3DScale(transform, 1 - scale , 1 - scale, 1.0)
        applyTransform(index, transform: transform)
    }

    func animationLinear(with index: Int, withOffset offset: CGFloat) {
        var transform = CATransform3DIdentity
        let mx = (1.0 - offset) * 100
        transform = CATransform3DTranslate(transform, mx * subviewsSpeed[index].x, mx * subviewsSpeed[index].y, 0 )
        applyTransform(index, transform: transform)
    }

    func animationInOut(with index: Int, withOffset offset: CGFloat) {
        var transform = CATransform3DIdentity
        // CGFloat x = (1.0 - offset) * 20;
        var tmpOffset = offset
        if tmpOffset > 1.0 {
            tmpOffset = 1.0 + (1.0 - tmpOffset)
        }
        transform = CATransform3DTranslate(transform, (1.0 - tmpOffset) * subviewsSpeed[index].x * 100, (1.0 - tmpOffset) * subviewsSpeed[index].y * 100, 0)
        applyTransform(index, transform: transform)
    }
    private func applyTransform(_ index:Int, transform: CATransform3D){
        let subview = view.subviews[index]
        if !notAnimatableViews.contains(subview.tag){
            view.subviews[index].layer.transform = transform
        }
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
