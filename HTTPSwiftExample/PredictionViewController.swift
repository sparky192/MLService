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
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var predictButton: UIButton!
    @IBOutlet weak var updateModel: UIButton!
    
    
    //MARK: Class Variables
    let motion = CMMotionManager()
    let motionOperationQueue = OperationQueue()
    var ringBuffer = RingBuffer(withSize: 1000)
    var globalMag = 0.0
    var session = URLSession()
    let operationQueue = OperationQueue()
    var dsid: Int?
    var alert:UIAlertController?
    var label = Classifier.KNN
    
    enum Classifier {
        case KNN
        case SVM
    }
    
    

    override func viewDidLoad() {
        self.prepareLabel()
        self.prepareImageView()
        self.prepareButtons()
        self.segmentControl.tintColor = .newBlue
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
                                  delegate: self,
                                  delegateQueue:self.operationQueue)
    }
    
    func prepareLabel() {
        predictionLabel.text = "Still"
        predictionLabel.textColor = .newOrange
    }
    
    func prepareImageView() {
        imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .newOrange
    }
    
    func prepareButtons() {
        updateModel.setTitleColor(.newYellow, for: .normal)
        updateModel.layer.borderColor = UIColor.newYellow.cgColor
        updateModel.layer.cornerRadius = 5
        updateModel.layer.borderWidth = 1
        
        predictButton.setTitleColor(.newGreen, for: .normal)
        predictButton.layer.borderColor = UIColor.newGreen.cgColor
        predictButton.layer.cornerRadius = 5
        predictButton.layer.borderWidth = 1
    }
    
    func prepareAlertView(title:String, text: String) {
        alert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        self.present(alert!, animated: true, completion: nil)
    }
    
    func endPrediction() {
        self.alert?.dismiss(animated: true, completion: nil)
        self.motion.stopDeviceMotionUpdates()
        self.getPrediction(ringBuffer.getDataAsVector())
        self.ringBuffer.reset()
   
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
            
            print("Mag: ", mag)
        }
    }
    
    //MARK: Button Actions
    
    @IBAction func updateModelButtonPressed(_ sender: Any) {
        if self.segmentControl.selectedSegmentIndex == 0 {
            label = Classifier.KNN

        } else if self.segmentControl.selectedSegmentIndex == 1  {
            label = Classifier.SVM
        }
        
        self.makeModel()
    }
    
    @IBAction func predictButtonPressed(_ sender: Any) {
        
        self.prepareAlertView(title: "Predicting", text: "Move or stay still to get Prediction")
        self.startMotionUpdates()
     
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: {_ in
            
            self.endPrediction()
            
        })
        
    }
    
    //MARK: Comm with Server
    func getPrediction(_ array:[Double]){
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array, "dsid":self.dsid]
        
        
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
            imageView.image = #imageLiteral(resourceName: "running")
            imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = .newRed
            
            break
        case "['walking']":
            predictionLabel.text = "Walking"
            imageView.image = #imageLiteral(resourceName: "pedestrian-walking")
            imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = .newBlue
            break
        case "['still']":
            predictionLabel.text = "Still"
            imageView.image = #imageLiteral(resourceName: "smartphone-call 2x")
            imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = .newBlue
            break
        default:
            print("Unknown")
            break
        }
    }
    
    func makeModel() {
    
    // create a GET request for server to update the ML model with current data
        let baseURL = "\(SERVER_URL)/UpdateModel"
        let query = "?dsid=\(self.dsid)&classifier=\(self.label)"
        
        let getUrl = URL(string: baseURL + query)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                completionHandler:{(data, response, error) in
                                                        // handle error!
                                                                    if (error != nil) {
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        
                                                                        if let resubAcc = jsonDictionary["resubAccuracy"]{
                                                                            print("Resubstitution Accuracy is", resubAcc)
                                                                        }
                                                                    }
                                                                    
        })
        
        dataTask.resume() // start the task
    
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
