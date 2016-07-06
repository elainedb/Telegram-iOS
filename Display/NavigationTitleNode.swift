import UIKit
import AsyncDisplayKit

public class NavigationTitleNode: ASDisplayNode {
    private let label: ASTextNode
    
    private var _text: NSString = ""
    public var text: NSString {
        get {
            return self._text
        }
        set(value) {
            self._text = value
            self.setText(value)
        }
    }
    
    public var color: UIColor = UIColor.black() {
        didSet {
            self.setText(self._text)
        }
    }
    
    public init(text: NSString) {
        self.label = ASTextNode()
        self.label.maximumNumberOfLines = 1
        self.label.truncationMode = .byTruncatingTail
        self.label.displaysAsynchronously = false
        
        super.init()
        
        self.addSubnode(self.label)
        
        self.setText(text)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setText(_ text: NSString) {
        var titleAttributes = [String : AnyObject]()
        titleAttributes[NSFontAttributeName] = UIFont.boldSystemFont(ofSize: 17.0)
        titleAttributes[NSForegroundColorAttributeName] = self.color
        let titleString = AttributedString(string: text as String, attributes: titleAttributes)
        self.label.attributedString = titleString
        self.invalidateCalculatedLayout()
    }
    
    public override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        self.label.measure(constrainedSize)
        return self.label.calculatedSize
    }
    
    public override func layout() {
        self.label.frame = self.bounds
    }
}
