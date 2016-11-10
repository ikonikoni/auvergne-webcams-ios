//
//  NavigationController.swift
//  UPA
//
//  Created by Drusy on 07/05/2016.
//  Copyright © 2016 Openium. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    
    fileprivate var shadowImageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.isTranslucent = true
        navigationBar.barStyle = .black
        navigationBar.tintColor = UIColor.white
      
//        let attributes = [
//            NSForegroundColorAttributeName: UIColor.white,
//            NSFontAttributeName: UIFont.openSansCondensedFont(withSize: 20)
//        ]
//        navigationBar.titleTextAttributes = attributes
//        
//        UINavigationBar.appearance().titleTextAttributes = attributes
//        UIBarButtonItem.appearance().setTitleTextAttributes(attributes, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if shadowImageView == nil {
            shadowImageView = findShadowImage(under: navigationBar)
        }
        shadowImageView?.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        shadowImageView?.isHidden = false
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // MARK: -
    
    func update() {
        if self.topViewController != nil && self.topViewController!.responds(to: #selector(update)) {
            _ = topViewController?.perform(#selector(update))
        }
    }
    
    // MARK: - 
    
    fileprivate func findShadowImage(under view: UIView) -> UIImageView? {
        if view is UIImageView && view.bounds.size.height <= 1 {
            return (view as! UIImageView)
        }
        
        for subview in view.subviews {
            if let imageView = findShadowImage(under: subview) {
                return imageView
            }
        }
        return nil
    }
}