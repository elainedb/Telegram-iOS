import UIKit

enum NavigationTransition {
    case Push
    case Pop
}

private let shadowWidth: CGFloat = 16.0

private func generateShadow() -> UIImage? {
    return UIImage(named: "NavigationShadow", in: Bundle(for: NavigationBackButtonNode.self), compatibleWith: nil)?.precomposed().resizableImage(withCapInsets: UIEdgeInsetsZero, resizingMode: .tile)
}

private let shadowImage = generateShadow()

class NavigationTransitionCoordinator {
    private var _progress: CGFloat = 0.0
    var progress: CGFloat {
        get {
            return self._progress
        }
        set(value) {
            self._progress = value
            self.updateProgress()
        }
    }
    
    private let container: UIView
    private let transition: NavigationTransition
    private let topView: UIView
    private let viewSuperview: UIView?
    private let bottomView: UIView
    private let topNavigationBar: NavigationBar?
    private let bottomNavigationBar: NavigationBar?
    private let dimView: UIView
    private let shadowView: UIImageView
    
    private let inlineNavigationBarTransition: Bool
    
    init(transition: NavigationTransition, container: UIView, topView: UIView, topNavigationBar: NavigationBar?, bottomView: UIView, bottomNavigationBar: NavigationBar?) {
        self.transition = transition
        self.container = container
        self.topView = topView
        switch transition {
            case .Push:
                self.viewSuperview = bottomView.superview
            case .Pop:
                self.viewSuperview = topView.superview
        }
        self.bottomView = bottomView
        self.topNavigationBar = topNavigationBar
        self.bottomNavigationBar = bottomNavigationBar
        self.dimView = UIView()
        self.dimView.backgroundColor = UIColor.black()
        self.shadowView = UIImageView(image: shadowImage)
        
        if let topNavigationBar = topNavigationBar, bottomNavigationBar = bottomNavigationBar {
            var topFrame = topNavigationBar.view.convert(topNavigationBar.bounds, to: container)
            var bottomFrame = bottomNavigationBar.view.convert(bottomNavigationBar.bounds, to: container)
            topFrame.origin.x = 0.0
            bottomFrame.origin.x = 0.0
            self.inlineNavigationBarTransition = topFrame.equalTo(bottomFrame)
        } else {
            self.inlineNavigationBarTransition = false
        }
        
        switch transition {
            case .Push:
                self.viewSuperview?.insertSubview(topView, belowSubview: topView)
            case .Pop:
                self.viewSuperview?.insertSubview(bottomView, belowSubview: topView)
        }
        
        self.viewSuperview?.insertSubview(self.dimView, belowSubview: topView)
        self.viewSuperview?.insertSubview(self.shadowView, belowSubview: dimView)
        
        self.maybeCreateNavigationBarTransition()
        self.updateProgress()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateProgress() {
        let position: CGFloat
        switch self.transition {
            case .Push:
                position = 1.0 - progress
            case .Pop:
                position = progress
        }
        
        var dimInset: CGFloat = 0.0
        if let topNavigationBar = self.topNavigationBar where self.inlineNavigationBarTransition {
            dimInset = topNavigationBar.frame.size.height
        }
        
        let containerSize = self.container.bounds.size
        
        self.topView.frame = CGRect(origin: CGPoint(x: floorToScreenPixels(position * containerSize.width), y: 0.0), size: containerSize)
        self.dimView.frame = CGRect(origin: CGPoint(x: 0.0, y: dimInset), size: CGSize(width: max(0.0, self.topView.frame.minX), height: self.container.bounds.size.height - dimInset))
        self.shadowView.frame = CGRect(origin: CGPoint(x: self.dimView.frame.maxX - shadowWidth, y: dimInset), size: CGSize(width: shadowWidth, height: containerSize.height - dimInset))
        self.dimView.alpha = (1.0 - position) * 0.15
        self.shadowView.alpha = (1.0 - position) * 0.9
        self.bottomView.frame = CGRect(origin: CGPoint(x: ((position - 1.0) * containerSize.width * 0.3), y: 0.0), size: containerSize)
        
        self.updateNavigationBarTransition()
    }
    
    func updateNavigationBarTransition() {
        if let topNavigationBar = self.topNavigationBar, bottomNavigationBar = self.bottomNavigationBar {
            let position: CGFloat
            switch self.transition {
                case .Push:
                    position = 1.0 - progress
                case .Pop:
                    position = progress
            }
            
            topNavigationBar.transitionState = NavigationBarTransitionState(navigationBar: bottomNavigationBar, transition: self.transition, role: .top, progress: position)
            bottomNavigationBar.transitionState = NavigationBarTransitionState(navigationBar: topNavigationBar, transition: self.transition, role: .bottom, progress: position)
        }
    }
    
    func maybeCreateNavigationBarTransition() {
        if let topNavigationBar = self.topNavigationBar, bottomNavigationBar = self.bottomNavigationBar {
            let position: CGFloat
            switch self.transition {
                case .Push:
                    position = 1.0 - progress
                case .Pop:
                    position = progress
            }
            
            topNavigationBar.transitionState = NavigationBarTransitionState(navigationBar: bottomNavigationBar, transition: self.transition, role: .top, progress: position)
            bottomNavigationBar.transitionState = NavigationBarTransitionState(navigationBar: topNavigationBar, transition: self.transition, role: .bottom, progress: position)
        }
    }
    
    func endNavigationBarTransition() {
        if let topNavigationBar = self.topNavigationBar, bottomNavigationBar = self.bottomNavigationBar {
            topNavigationBar.transitionState = nil
            bottomNavigationBar.transitionState = nil
        }
    }
    
    func animateCancel(_ completion: () -> ()) {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.progress = 0.0
        }) { (completed) -> Void in
            switch self.transition {
                case .Push:
                    if let viewSuperview = self.viewSuperview {
                        viewSuperview.addSubview(self.bottomView)
                    } else {
                        self.bottomView.removeFromSuperview()
                    }
                    self.topView.removeFromSuperview()
                case .Pop:
                    if let viewSuperview = self.viewSuperview {
                        viewSuperview.addSubview(self.topView)
                    } else {
                        self.topView.removeFromSuperview()
                    }
                    self.bottomView.removeFromSuperview()
            }
            
            self.dimView.removeFromSuperview()
            self.shadowView.removeFromSuperview()
            
            self.endNavigationBarTransition()
            
            completion()
        }
    }
    
    func animateCompletion(_ velocity: CGFloat, completion: () -> ()) {
        let distance = (1.0 - self.progress) * self.container.bounds.size.width
        let f = {
            switch self.transition {
                case .Push:
                    if let viewSuperview = self.viewSuperview {
                        viewSuperview.addSubview(self.bottomView)
                    } else {
                        self.bottomView.removeFromSuperview()
                    }
                case .Pop:
                    if let viewSuperview = self.viewSuperview {
                        viewSuperview.addSubview(self.topView)
                    } else {
                        self.topView.removeFromSuperview()
                    }
            }
            
            self.dimView.removeFromSuperview()
            self.shadowView.removeFromSuperview()
            
            self.endNavigationBarTransition()
            
            completion()
        }
        
        if abs(velocity) < CGFloat(FLT_EPSILON) && abs(self.progress) < CGFloat(FLT_EPSILON) {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions(rawValue: 7 << 16), animations: {
                self.progress = 1.0
            }, completion: { _ in
                f()
            })
        } else {
            UIView.animate(withDuration: Double(max(0.05, min(0.2, abs(distance / velocity)))), delay: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                self.progress = 1.0
            }) { (completed) -> Void in
                f()
            }
        }
    }
}
