//
//  VXWalkthroughViewController.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 09.12.19.
//

import Foundation
import UIKit

@objc
protocol VXWalkthroughViewControllerDelegate: NSObjectProtocol {
    @objc optional func walkthroughCloseButtonPressed(_ sender: Any?) // If the skipRequest(sender:) action is connected to a button, this function is called when that button is pressed.
    @objc optional func walkthroughNextButtonPressed() //
    @objc optional func walkthroughPrevButtonPressed() //
    @objc optional func walkthroughPageDidChange(_ pageNumber: Int) // Called when current page changes
    @objc optional func walkthroughActionButtonPressed(_ pSender: Any?, item: [String : Any]?)
}

// Walkthrough Page:
// The walkthrough page represents any page added to the Walkthrough.
// At the moment it's only used to perform custom animations on didScroll.
@objc
protocol VXWalkthroughPage: AnyObject {
    // While sliding to the "next" slide (from right to left), the "current" slide changes its offset from 1.0 to 2.0 while the "next" slide changes it from 0.0 to 1.0
    // While sliding to the "previous" slide (left to right), the current slide changes its offset from 1.0 to 0.0 while the "previous" slide changes it from 2.0 to 1.0
    // The other pages update their offsets whith values like 2.0, 3.0, -2.0... depending on their positions and on the status of the walkthrough
    // This value can be used on the previous, current and next page to perform custom animations on page's subviews.
    @objc func walkthroughDidScroll(_ position: CGFloat, withOffset offset: CGFloat) // Called when the main Scrollview...scroll
    var key: String? { get }
}

class VXWalkthroughViewController: UIViewController, UIScrollViewDelegate {
    // - MARK: Constants
    static let kTitle = "title"
    static let kImage = "image"
    static let kStoryBoardID = "storyboardID"
    static let kOptions = "options"

    static let kPickerValue = "pickerValue"
    static let kLoginValue = "loginValue"
    static let kEmailValue = "emailValue"
    static let kPasswordValue = "passwordValue"

    static let kEmailPrompt = "emailPrompt"
    static let kLoginPrompt = "loginPrompt"
    static let kPasswordPrompt = "passwordPrompt"
    static let kButtonTitle = "buttonTitle"
    static let kPlaceholderValue = "placeholderValue"
    static let kIsScanEnabled = "scanenabled"

    static let kSuccess = "success"
    static let kError = "error"

    static let kKey = "key"
    static let kSort = "sort"
    static let kAvailabe = "available"

    // - MARK: Walkthrough Delegate
    // This delegate performs basic operations such as dismissing the Walkthrough or call whatever action on page change.
    // Probably the Walkthrough is presented by this delegate.
    weak var delegate: VXWalkthroughViewControllerDelegate?

    // - MARK: Outlets
    // you need a page control, next or prev buttons add them via IB and connect them with these Outlets
    @IBOutlet var pageControl: UIPageControl?
    @IBOutlet var nextButton: UIButton?
    @IBOutlet var prevButton: UIButton?
    @IBOutlet var closeButton: UIButton?

    // - MARK: Properties
    var items = [String : Any]()

    var group: String?
    var roundImages = false
    var backgroundColor: UIColor?
    var styles = [String : Any]()
    var controllers = [UIViewController]()
    var lastViewConstraints = [NSLayoutConstraint]()


    lazy var scrollview: UIScrollView = {
        let v = UIScrollView()
        v.showsHorizontalScrollIndicator = false
        v.showsVerticalScrollIndicator = false
        v.isPagingEnabled = true
        v.delegate = self
        v.translatesAutoresizingMaskIntoConstraints = false

         //scrollview is inserted as first view of the hierarchy
        self.view.insertSubview(v, at: 0)

        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[scrollview]-0-|", options: [], metrics: nil, views: [
            "scrollview": v
        ]))

        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[scrollview]-0-|", options: [], metrics: nil, views: [
            "scrollview": v
        ]))

        return v
    }()

    class var storyboardName: String {
        return "VXWalkthroughViewController"
    }

    class var storyboardID: String {
        return "Walkthrough"
    }
    // The index of the current page (readonly)
    open var currentPage: Int {
        get{
            let page = Int((scrollview.contentOffset.x / view.bounds.size.width))
            return page
        }
    }

    open var currentViewController: UIViewController {
        get{
            let currentPage = self.currentPage
            return controllers[currentPage]
        }
    }

    open var numberOfPages: Int{
        get {
            return self.controllers.count
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.roundImages = true
    }
    override public func viewDidLoad() {
       super.viewDidLoad()
        if let i = UIImage(named: "VXWalkthroughController.bundle/VXWalkthroughViewControllerLeftArrow@2x.png") {
            self.prevButton?.setImage(i, for: .normal)
        }
        if let i = UIImage(named: "VXWalkthroughController.bundle/VXWalkthroughViewControllerRightArrow@2x.png") {
            self.nextButton?.setImage(i, for: .normal)
        }
        self.pageControl?.addTarget(self, action: #selector(pageControlDidTouch), for: UIControl.Event.touchUpInside)

       // load walkthrough
       self.load()
       self.roundImages = true

    }

    override public func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)

        self.pageControl?.numberOfPages = self.controllers.count
        self.pageControl?.currentPage = 0

        self.updateUI()

       let appVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
       let startInfoKey = "vxwalkthroughshown_\(appVersion ?? "")"

       UserDefaults.standard.set(true, forKey: startInfoKey)
       UserDefaults.standard.synchronize()
    }
    class func walkthroughShown() -> Bool {
       // check if the startup info has been shown for the current release
       let appVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
       let startInfoKey = "vxwalkthroughshown_\(appVersion ?? "")"

       let walkthroughShown = UserDefaults.standard.bool(forKey: startInfoKey)

       return walkthroughShown
    }

    class func create(delegate: VXWalkthroughViewControllerDelegate, backgroundColor: UIColor?, styles: [String : Any]? = nil) -> VXWalkthroughViewController? {
        let bundle = Bundle(for: VXWalkthroughViewController.self)

        let stb = UIStoryboard(name: VXWalkthroughViewController.storyboardName, bundle: bundle)

        let walkthrough = stb.instantiateViewController(withIdentifier: VXWalkthroughViewController.storyboardID) as? VXWalkthroughViewController

        walkthrough?.backgroundColor = backgroundColor
        walkthrough?.delegate = delegate
        if let s = styles {
            walkthrough?.styles = s
        }
        walkthrough?.roundImages = true
        return walkthrough
    }


     func createPageViewController(_ key: String, item: [String : Any]?) -> VXWalkthroughPageViewController? {
        let bundle = Bundle(for: self.classForCoder)

        let stb = UIStoryboard(name: VXWalkthroughViewController.storyboardName, bundle: bundle)
        //    stb = UIStoryboard(name: VXWalkthroughViewController.storyboardName, bundle: nil)

        let storyboardID = (item?["storyboardID"] as? String) ?? VXWalkthroughPageViewController.storyboardID
        if let vc = stb.instantiateViewController(withIdentifier: storyboardID) as? VXWalkthroughPageViewController {
            vc.styles = styles
            vc.roundImages = roundImages
            vc.parentController = self
            vc.view.backgroundColor = self.backgroundColor
            vc.view.isOpaque = false
            vc.item = item
            return vc
        }
        return nil
    }

    func createItem(_ key: String, item: [String : Any]?) -> [String : Any]? {
        let text = NSLocalizedString(key, comment: "")
        let buttonTitle = NSLocalizedString(key , comment: "")

        let imageName = key

        let itemMore: [String : Any] = [
            VXWalkthroughViewController.kKey: key,
            VXWalkthroughViewController.kTitle: text,
            VXWalkthroughViewController.kImage: imageName,
            VXWalkthroughViewController.kSort: 1,
            VXWalkthroughViewController.kButtonTitle: buttonTitle
        ]

        var itemResult = itemMore

        if let item = item {
            for (k, v) in item {
                itemResult[k] = v
            }
        }
        return itemResult
    }

    public func populate(useDefault: Bool = true) {
        self.items = [String : Any]()

        if useDefault {
            // setup pages
            var step = 0
            var stepKey = String(format: "walkthrough_%li", step)

            var stepText = NSLocalizedString(stepKey, comment: "")

            while !stepText.isEmpty && !(stepText == stepKey) {
                let item: [String : Any] = [
                    VXWalkthroughViewController.kKey: stepKey,
                    VXWalkthroughViewController.kTitle: stepText,
                    VXWalkthroughViewController.kImage: stepKey,
                    VXWalkthroughViewController.kSort: NSNumber(value: step * 10)
                ]
                items[stepKey] = item

                step += 1

                stepKey = String(format: "walkthrough_%li", step)
                stepText = NSLocalizedString(stepKey, comment: "")
            }
        }
    }

    func load() {
        if self.items.isEmpty {
            populate()
        }

        if controllers.isEmpty {
            let itemsSorted = items.sorted {
                guard let d1 = $0.1 as? [String: Any], let d2 = $1.1 as? [String: Any] else {
                    return false
                }
                guard let s1 = d1[VXWalkthroughViewController.kSort], let s2 = d2[VXWalkthroughViewController.kSort] else {
                    return false
                }
                guard let v1 = s1 as? Int, let v2 = s2 as? Int else {
                    return false
                }

                return v1 < v2
            }
            for item in itemsSorted {
                if let vc = self.createPageViewController(item.key, item: item.value as? [String: Any]) {
                    add(vc)
                }
            }
        }

        self.view.backgroundColor = backgroundColor
    }
    func controller(key: String) -> UIViewController? {
        let controller = self.controllers.first { (vc) -> Bool in
            if let wvc = vc as? VXWalkthroughPage {
                return wvc.key == key
            } else {
                return false
            }
        }
        return controller
    }
    @IBAction func nextPage() {
        if currentPage + 1 < controllers.count {
            delegate?.walkthroughNextButtonPressed?()
            gotoPage(currentPage + 1)
        }
    }

    @IBAction func prevPage() {
        if currentPage > 0 {
            delegate?.walkthroughPrevButtonPressed?()
            gotoPage(currentPage - 1)

        }
    }
    @objc func pageControlDidTouch(){
        if let pc = pageControl{
           gotoPage(pc.currentPage)
        }
    }
    fileprivate func gotoPage(_ page:Int){
        if page < controllers.count{
            var frame = scrollview.frame
            frame.origin.x = CGFloat(page) * frame.size.width
            scrollview.scrollRectToVisible(frame, animated: true)
        }
    }

    // TODO: If you want to implement a "skip" option
    // connect a button to this IBAction and implement the delegate with the skipWalkthrough
    @IBAction func close(_ sender: Any) {
        delegate?.walkthroughCloseButtonPressed?(self)
    }

    // Add a new page to the walkthrough.
    // To have information about the current position of the page in the walkthrough add a UIVIewController which implements BWWalkthroughPage

    func add(_ vc: UIViewController) {
        controllers.append(vc)
        self.addChild(vc)
        vc.didMove(toParent: self)


        // Setup the viewController view
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        if let view = vc.view {
            scrollview.addSubview(view)
            // Constraints

            let metricDict: [String: Any] = [
                "w": vc.view.bounds.size.width,
                "h": vc.view.bounds.size.height
            ]
            let viewsDict: [String: Any] = [
                "view": view,
                "container": scrollview
            ]

            // - Generic cnst
            scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(==container)]", options:[], metrics: metricDict, views: viewsDict))
            scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[view(==container)]", options:[], metrics: metricDict, views: viewsDict))
            scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]|", options:[], metrics: nil, views: viewsDict))

            if controllers.count == 1 {
                scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]", options:[], metrics: nil, views: ["view": view]))

            } else {
                let previousVC = controllers[controllers.count - 2]
                let previousView = previousVC.view

                if let previousView = previousView {
                    scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[previousView]-0-[view]", options:[], metrics: nil, views: ["previousView": previousView, "view": view]))
                }
                if !lastViewConstraints.isEmpty {
                    scrollview.removeConstraints(lastViewConstraints)
                }
                lastViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[view]-0-|", options:[], metrics: nil, views: ["view": view])
                scrollview.addConstraints(lastViewConstraints)
            }
        }
    }

    //Update the UI to reflect the current walkthrough situation

    func updateUI() {
        // Get the current page
        pageControl?.currentPage = currentPage

        // Notify delegate about the new page
        delegate?.walkthroughPageDidChange?(currentPage)

        // Hide/Show navigation buttons
        if currentPage == controllers.count - 1 || controllers.count == 1 {
            nextButton?.isHidden = true
        } else {
            nextButton?.isHidden = false
        }

        if currentPage == 0 || controllers.count == 1 {
            prevButton?.isHidden = true
        } else {
            prevButton?.isHidden = false
        }
        pageControl?.isHidden = controllers.count <= 1
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for i in 0..<controllers.count {
            if let vc = controllers[i] as? VXWalkthroughPage{
                let mx = ((scrollView.contentOffset.x + view.bounds.size.width) - (view.bounds.size.width * CGFloat(i))) / view.bounds.size.width

                // While sliding to the "next" slide (from right to left), the "current" slide changes its offset from 1.0 to 2.0 while the "next" slide changes it from 0.0 to 1.0
                // While sliding to the "previous" slide (left to right), the current slide changes its offset from 1.0 to 0.0 while the "previous" slide changes it from 2.0 to 1.0
                // The other pages update their offsets whith values like 2.0, 3.0, -2.0... depending on their positions and on the status of the walkthrough
                // This value can be used on the previous, current and next page to perform custom animations on page's subviews.

                // print the mx value to get more info.
                // println("\(i):\(mx)")

                // We animate only the previous, current and next page
                if mx < 2 && mx > -2.0 {
                    vc.walkthroughDidScroll(scrollView.contentOffset.x, withOffset: mx)
                }
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateUI()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateUI()
    }

    override var shouldAutorotate: Bool {
        return false
    }
    fileprivate func adjustOffsetForTransition() {

        // Get the current page before the transition occurs, otherwise the new size of content will change the index
        let currentPage = self.currentPage

        let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * 0.1 )) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            [weak self] in
            self?.gotoPage(currentPage)
        }
    }

    override open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        adjustOffsetForTransition()
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        adjustOffsetForTransition()
    }
}
