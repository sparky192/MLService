//
//  PredictionViewController.swift
//  HTTPSwiftExample
//
//  Created by Gabriel I Leyva Merino on 11/9/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion

class PredictionViewController: UIViewController, URLSessionDelegate {
    
    //MARK: UI Elements
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    let motion = CMMotionManager()
    let motionOperationQueue = OperationQueue()
    var ringBuffer = RingBuffer(withSize: 1000)
    var globalMag = 0.0
    
    override func viewDidLoad() {
        self.prepareLabel()
        self.prepareImageView()
        self.startMotionUpdates()
    }
    
    func prepareLabel() {
        predictionLabel.text = "Still"
        predictionLabel.textColor = .newOrange
    }
    
    func prepareImageView() {
        imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .newOrange
    }
    
    
    // MARK: Core Motion Updates
    func startMotionUpdates(){
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 1.0/200
            self.motion.startDeviceMotionUpdates(to: motionOperationQueue, withHandler: self.handleMotion )
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let accel = motionData?.userAcceleration {
            // Send the data from here
            
            self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
            let mag = fabs(accel.x)+fabs(accel.y)+fabs(accel.z)
            globalMag = mag
            print("Mag: ", mag)
        }
    }
    

    
    
}
