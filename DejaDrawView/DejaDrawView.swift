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



class VaryingWidthPen: DrawingTool {
    var maxWidth: CGFloat = 3.0
    var minWidth: CGFloat = 1.0
    var f: CGFloat = 0.02
    
    func drawHistory(history: TouchHistory) {
        let path = self.bezierPathFromHistory(history)
        UIColor.blackColor().setFill()
        path.fillWithBlendMode(CGBlendMode.Darken, alpha: 1.0)
    }
    
    func bezierPathFromHistory(history: TouchHistory) -> UIBezierPath {
        guard history.touchPoints.count > 1 else { return UIBezierPath() }
        
        let path = UIBezierPath()
        path.lineCapStyle = .Round
        path.lineWidth = 1.0
        
        let tps = history.touchPoints.map { tp in return tp.point }
        if tps.count >= 3 {
            var upper = [tps[0]]
            var lower = [tps[0]]
            var prevprev: CGPoint!
            var prev = tps[0]
            var current = tps[1]
            for i in 2 ..< tps.count {
                prevprev = prev
                prev = current
                current = tps[i]
                
                let perp = perpendicular(prevprev, current)
                let d1 = dist(prevprev, prev)
                let d2 = dist(prev, current)
                let r = maxWidth + minWidth - min(max(f * (d1 + d2), minWidth), maxWidth)
                
                upper.append(CGPoint(x: prev.x + r * perp.x, y: prev.y + r * perp.y))
                lower.append(CGPoint(x: prev.x + -r * perp.x, y: prev.y + -r * perp.y))
            }
            upper.append(current)
            
            path.moveToPoint(upper.first!)
            self.appendTouchPoints(path, touchPoints: upper)
            self.appendTouchPoints(path, touchPoints: lower.reverse())
            path.closePath()
        } else {
            // Dot
            let first = tps[0]
            let second = tps[1]
            let mid = midPoint(first, second)
            let midDist = dist(first, mid)
    
            path.moveToPoint(first)
            let startAngle: CGFloat = 0.0
            let endAngle: CGFloat = CGFloat(2.0 * M_PI)
            path.addArcWithCenter(mid, radius: max(3.0, min(midDist, 1.0)), startAngle: startAngle, endAngle: endAngle, clockwise: true)
        }
        
        return path
    }
    
    func appendTouchPoints(path: UIBezierPath, touchPoints: [CGPoint]) {
        var prev = touchPoints[0]
        var current = touchPoints[0]
        
        for i in 1 ..< touchPoints.count {
            current = touchPoints[i]
            let mid = midPoint(prev, current)
            path.addQuadCurveToPoint(mid, controlPoint: prev)
            prev = current
        }
        
        path.addLineToPoint(current)
    }
    
    func perpendicular(p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let px = -dy
        let py = dx
        let len = sqrt(pow(px, 2) + pow(py, 2))
        
        let f: CGFloat
        if len == 0.0 {
            f = 0.0
        } else {
            f = 1.0 / len
        }
        
        return CGPointMake(px * f, py * f)
    }
    
    func clamp(d: CGFloat) -> CGFloat {
        return max(min(8.0, d), 2.0)
    }
}



// MARK: - DejaDrawView

class DejaDrawView: UIView {

    // MARK: Properties
    var history = TouchHistory()
    var currentTool = VaryingWidthPen()
    var committedImage = UIImage()

    
    
    // MARK: Methods
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    
    
    func configure() {
        let long = UILongPressGestureRecognizer(target: self, action: Selector("erase:"))
        self.addGestureRecognizer(long)
    }
    
    
    
    func erase(rec: UIGestureRecognizer) {
        committedImage = UIImage()
        history = TouchHistory()
        self.setNeedsDisplay()
    }
    
    
    
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
        
        let s: [UITouch]?
        if #available(iOS 9.0, *) {
            s = UIEvent.coalescedTouchesForTouch(event!)(touch)
        } else {
            s = [touch]
        }
        
        guard let stableTouches = s else { return }
        
        let p: [UITouch]?
        if #available(iOS 9.0, *) {
            p = UIEvent.predictedTouchesForTouch(event!)(touch)
        } else {
            p = [touch]
        }
        
        guard let predictedTouches = p else { return }
        
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

        let s: [UITouch]?
        if #available(iOS 9.0, *) {
            s = UIEvent.coalescedTouchesForTouch(event!)(touch)
        } else {
            s = [touch]
        }
        
        guard let stableTouches = s else { return }
        
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




