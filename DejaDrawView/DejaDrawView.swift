//
//  DejaDrawView.swift
//  DejaDrawView
//
//  Created by Markus Schlegel on 11/07/15.
//  Copyright (c) 2015 Markus Schlegel. All rights reserved.
//

import UIKit




// MARK: Data structures

enum TouchPointStatus {
    case Stable
    case Predicted
}



struct TouchPoint {
    let point: CGPoint
    let status: TouchPointStatus
}



struct TouchHistory {
    var touchPoints = [TouchPoint]()
    
    func stableTouchPoints() -> [TouchPoint] {
        return self.touchPoints.filter {
            elem in return elem.status == .Stable
        }
    }
    
    func predictedTouchPoints() -> [TouchPoint] {
        return self.touchPoints.filter {
            elem in return elem.status == .Predicted
        }
    }
    
    func lastStablePoint() -> CGPoint? {
        return self.stableTouchPoints().last?.point
    }
    
    mutating func appendStablePoint(point: CGPoint) {
        self.touchPoints.append(TouchPoint(point: point, status: .Stable))
    }
    
    mutating func appendPredictedPoint(point: CGPoint) {
        self.touchPoints.append(TouchPoint(point: point, status: .Predicted))
    }
    
    mutating func appendTouchPoint(touchPoint: TouchPoint) {
        self.touchPoints.append(touchPoint)
    }
    
    mutating func removePredictedTouchPoints() {
        while self.touchPoints.last?.status == .Predicted {
            self.touchPoints.removeLast()
        }
    }
}



// MARK: - Tools
protocol DrawingTool {
    func drawHistory(history: TouchHistory)
}



class Pen: DrawingTool {
    func drawHistory(history: TouchHistory) {
        let path = self.bezierPathFromHistory(history)
        UIColor.blackColor().setStroke()
        path.stroke()
    }
    
    func bezierPathFromHistory(history: TouchHistory) -> UIBezierPath {
        guard history.touchPoints.count > 0 else { return UIBezierPath() }
        
        let path = UIBezierPath()
        path.lineCapStyle = .Round
        path.lineWidth = 4.0
        
        var prev = history.touchPoints[0].point
        var current = history.touchPoints[0].point
        path.moveToPoint(prev)
        
        for i in 1 ..< history.touchPoints.count {
            current = history.touchPoints[i].point
            let mid = midPoint(prev, current)
            path.addQuadCurveToPoint(mid, controlPoint: prev)
            prev = current
        }
        
        path.addLineToPoint(current)
        
        return path
    }
}



// MARK: - DejaDrawView

class DejaDrawView: UIView {

    // MARK: Properties
    var history = TouchHistory()
    var currentTool = Pen()
    var shouldCommit = false
    var committedImage = UIImage()

    
    
    // MARK: Methods
    override func drawRect(rect: CGRect) {
        self.committedImage.drawAtPoint(CGPointZero)
        self.currentTool.drawHistory(self.history)
    }
    
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let currentPoint = touch.locationInView(self)
        self.history = TouchHistory(touchPoints: [TouchPoint(point: currentPoint, status: .Stable)])
        
        self.setNeedsDisplay()
    }
    
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let stableTouches = UIEvent.coalescedTouchesForTouch(event!)(touch) else { return }
        guard let predictedTouches = UIEvent.predictedTouchesForTouch(event!)(touch) else { return }
        
        self.history.removePredictedTouchPoints()
        
        for t in stableTouches {
            self.history.appendStablePoint(t.locationInView(self))
        }
        
        for t in predictedTouches {
            self.history.appendPredictedPoint(t.locationInView(self))
        }
        
        self.setNeedsDisplay()
    }
    
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let stableTouches = UIEvent.coalescedTouchesForTouch(event!)(touch) else { return }
        
        self.history.removePredictedTouchPoints()
        
        for t in stableTouches {
            self.history.appendStablePoint(t.locationInView(self))
        }
        
        // Save as bitmap
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
        self.committedImage.drawAtPoint(CGPointZero)
        self.currentTool.drawHistory(self.history)
        self.committedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.history = TouchHistory(touchPoints: [])
        
        self.setNeedsDisplay()
    }
}



// MARK: - Geometry functions

func controlPoints(a: CGPoint, _ b: CGPoint, _ c: CGPoint, t: CGFloat) -> (CGPoint, CGPoint) {
    let d_ab = dist(a, b)
    let d_bc = dist(b, c)
    let fa = t * d_ab / (d_ab + d_bc)
    let fb = t * d_bc / (d_ab + d_bc)
    let r = CGPointMake(b.x - fa * (c.x - a.x), b.y - fa * (c.y - a.y))
    let s = CGPointMake(b.x + fb * (c.x - a.x), b.y + fb * (c.y - a.y))
    
    return (r, s);
}



func dist(a: CGPoint, _ b: CGPoint) -> CGFloat {
    let r2: CGFloat = pow(b.x - a.x, 2.0)
    let s2: CGFloat = pow(b.y - a.y, 2.0)
    return sqrt(r2 + s2)
}



func midPoint(a: CGPoint, _ b: CGPoint) -> CGPoint {
    return CGPointMake(0.5 * (a.x + b.x), 0.5 * (a.y + b.y))
}




