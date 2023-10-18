//
//  TestView.swift
//  adyen_checkout
//
//  Created by Robert Schulze Dieckhoff on 18/10/2023.
//

import Foundation

class TestView : UIStackView {
    
    var handler : () -> Void
    
    init(handler: @escaping () -> Void) {
        self.handler = handler
        
        super.init(frame: .zero)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        handler()
        
        print("Layout custom view")
        print(bounds.height)
        print(subviews.first?.systemLayoutSizeFitting(.init(width: bounds.width, height: .greatestFiniteMagnitude)))
    }
}
