//
//  MotionManager.swift
//  
//
//  Created by Michael Verges on 7/31/20.
//

import SwiftUI
import CoreMotion
#if os(macOS)
import AppKit
#endif

internal class MotionManager: ObservableObject {
#if os(iOS)
  @Published var yaw: CGFloat = 0
  @Published var pitch: CGFloat = 0
  @Published var roll: CGFloat = 0
  
  var motionInput = CMMotionManager()
  var displayLink: CADisplayLink?
#elseif os(macOS)
  @Published var locationX: CGFloat = 0
  @Published var locationY: CGFloat = 0
  
  var motionInput = NSEvent()
#endif
  
  static var main = MotionManager()  
  
  init() {
#if os(iOS)
    motionInput.deviceMotionUpdateInterval = 0.2
#elseif os(macOS)
    NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
      let screenWidth = NSScreen.main?.frame.width ?? 1920
      let screenHeight = NSScreen.main?.frame.height ?? 1080
      self.locationX = -self.motionInput.locationX.remap(origFrom: 0, origTo: screenWidth, targetFrom: -.pi, targetTo: .pi) / 4
      self.locationY = self.motionInput.locationY.remap(origFrom: 0, origTo: screenHeight, targetFrom: -.pi, targetTo: .pi) / 4
      return $0
    }
#endif
    
    startUpdates()
  }
  
  deinit {
#if os(iOS)
    stopUpdates()
#endif
  }
}

#if os(iOS)
internal extension MotionManager {
  func startUpdates() {
    if !motionInput.isDeviceMotionActive && motionInput.isDeviceMotionAvailable {
      motionInput.startDeviceMotionUpdates()
      displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
      displayLink?.preferredFramesPerSecond = 24
      displayLink?.add(to: .main, forMode: .common)
    }
  }
  
  func stopUpdates() {
    displayLink?.invalidate()
    displayLink = nil
    motionInput.stopDeviceMotionUpdates()
  }
  
  @objc fileprivate func displayLinkFired(_ sender: CADisplayLink) {
    if let yaw = motionInput.yaw,
       let pitch = motionInput.pitch,
       let roll = motionInput.roll
    {
      self.yaw = CGFloat(yaw)
      self.pitch = CGFloat(pitch)
      self.roll = CGFloat(roll)
    }
  }
}

internal extension CMMotionManager {
  var yaw: Double? {
    get {
      return deviceMotion?.attitude.yaw
    }
  }
  
  var pitch: Double? {
    get {
      return deviceMotion?.attitude.pitch
    }
  }
  
  var roll: Double? {
    get {
      return deviceMotion?.attitude.roll
    }
  }
}

#elseif os(macOS)

internal extension NSEvent {
  var locationX: CGFloat {
    return NSEvent.mouseLocation.x
  }
  
  var locationY: CGFloat {
    return NSEvent.mouseLocation.y
  }
}

internal extension CGFloat {
  func lerp(from: CGFloat, to: CGFloat, rel: CGFloat) -> CGFloat {
    return ((1 - rel) * from) + (rel * to)
  }
  
  func invLerp(from: CGFloat, to: CGFloat, value: CGFloat) -> CGFloat {
    return (value - from) / (to - from)
  }
  
  func remap(origFrom: CGFloat, origTo: CGFloat, targetFrom: CGFloat, targetTo: CGFloat) -> CGFloat {
    let rel = invLerp(from: origFrom, to: origTo, value: self)
    return lerp(from: targetFrom, to: targetTo, rel: rel)
  }
}
#endif
