//  Copyright © 2017 Marcin Ukleja. All rights reserved.

import UIKit

extension UIView {
    
    func fadeTransition(duration: CFTimeInterval) {
        let animation: CATransition = CATransition()
        // animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = duration
        self.layer.add(animation, forKey: kCATransitionFade)
    }
    
    func pushRightTransition(duration:CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromRight
        animation.duration = duration
        self.layer.add(animation, forKey: kCATransitionPush)
    }
    
    func pushLeftTransition(duration:CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromLeft
        animation.duration = duration
        self.layer.add(animation, forKey: kCATransitionPush)
    }
}
