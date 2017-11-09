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
    
    
    //MARK: Class Variables
    let motion = CMMotionManager()
    let motionOperationQueue = OperationQueue()
    var ringBuffer = RingBuffer(withSize: 1000)
    var globalMag = 0.0
    var session = URLSession()
    let operationQueue = OperationQueue()
    var dsid: Int?
    
    

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
            
            //**** Uncomment to reuqest prediction from server ****
            //self.getPrediction(self.ringBuffer.getDataAsVector())
            print("Mag: ", mag)
        }
    }
    
    
    
    //MARK: Comm with Server
    func getPrediction(_ array:[Double]){
        let baseURL = "\(SERVER_URL)/PredictMovement"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array, "dsid":self.dsid!]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        print("Response:\n",response)
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        
                                                                        let labelResponse = jsonDictionary["prediction"]!
                                                                        print(labelResponse)
                                                                        self.displayLabelResponse(labelResponse as! String)
                                                                        
                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    func displayLabelResponse(_ response:String){
        switch response {
        case "['running']":
            predictionLabel.text = "Running"
            break
        case "['walking']":
            predictionLabel.text = "Walking"
            break
        case "['still']":
            predictionLabel.text = "Still"
            break
        default:
            print("Unknown")
            break
        }
    }
    
    
    //MARK: JSON Conversion Functions
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                                 options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            return NSDictionary() // just return empty
        }
    }
    
}
