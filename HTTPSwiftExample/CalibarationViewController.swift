//
//  CalibarationViewController.swift
//  HTTPSwiftExample
//
//  Created by Mandar Phadate on 11/8/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

import UIKit
import CoreMotion

class CalibarationViewController: UIViewController, URLSessionDelegate {
    
    // MARK: UIElements
    @IBOutlet weak var dsidLabel: UILabel!
    @IBOutlet weak var wCalibrationButton: UIButton!
    @IBOutlet weak var rCalibrationButton: UIButton!
    @IBOutlet weak var sCalibrationButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var dsidButton: UIButton!
    
    @IBOutlet weak var stillImageView: UIImageView!
    @IBOutlet weak var runningImageView: UIImageView!
    @IBOutlet weak var walkingImageView: UIImageView!
    
    
    // MARK: Class Properties
    var session = URLSession()
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    
    var ringBuffer = RingBuffer(withSize: 1000)
    let animation = CATransition()
    let motion = CMMotionManager()
    
    var magValue = 0.1
    var isCalibrating = false
    
    var isWaitingForMotionData = false
    
    
    enum CalibrationStage {
        case notCalibrating
        case walking
        case running
        case still
    }
    
    var dsid:Int = 0 {
        didSet{
            DispatchQueue.main.async{
                // update label when set
                self.dsidLabel.layer.add(self.animation, forKey: nil)
                self.dsidLabel.text = "Current DSID: \(self.dsid)"
            }
        }
    }
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareButtons()
        self.prepareImageViews()
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
                                  delegate: self,
                                  delegateQueue:self.operationQueue)
        
        // create reusable animation
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = 0.5
        
        self.dsid = 2

        // Do any additional setup after loading the view.
    }
    
    // MARK: Styling View
    
    func prepareButtons() {
        wCalibrationButton.tintColor = .newBlue
        wCalibrationButton.layer.borderColor = UIColor.newBlue.cgColor
        wCalibrationButton.layer.borderWidth = 1
        wCalibrationButton.layer.cornerRadius = 5
        wCalibrationButton.setTitleColor(.newBlue, for: .normal)

        
        rCalibrationButton.tintColor = .newRed
        rCalibrationButton.layer.borderColor = UIColor.newRed.cgColor
        rCalibrationButton.layer.borderWidth = 1
        rCalibrationButton.layer.cornerRadius = 5
        rCalibrationButton.setTitleColor(.newRed, for: .normal)

        
        sCalibrationButton.tintColor = .newOrange
        sCalibrationButton.layer.borderColor = UIColor.newOrange.cgColor
        sCalibrationButton.layer.borderWidth = 1
        sCalibrationButton.layer.cornerRadius = 5
        sCalibrationButton.setTitleColor(.newOrange, for: .normal)
        
        doneButton.tintColor = .newGreen
        doneButton.layer.borderColor = UIColor.newGreen.cgColor
        doneButton.layer.borderWidth = 1
        doneButton.layer.cornerRadius = 5
        doneButton.setTitleColor(.newGreen, for: .normal)
        
        dsidButton.tintColor = .newYellow
        dsidButton.layer.borderColor = UIColor.newYellow.cgColor
        dsidButton.layer.borderWidth = 1
        dsidButton.layer.cornerRadius = 5
        dsidButton.setTitleColor(.newYellow, for: .normal)
        
    }
    
    func prepareImageViews() {
        runningImageView.image = runningImageView.image!.withRenderingMode(.alwaysTemplate)
        runningImageView.tintColor = .newRed

        
        walkingImageView.image = walkingImageView.image!.withRenderingMode(.alwaysTemplate)
        walkingImageView.tintColor = .newBlue
        
        stillImageView.image = stillImageView.image!.withRenderingMode(.alwaysTemplate)
        stillImageView.tintColor = .newOrange
    }
    
    // MARK: Callibaration
    
    @IBAction func calibarateWalking(_ sender: UIButton) {
    }
    
    @IBAction func calibarateRunning(_ sender: UIButton) {
    }
    
    @IBAction func calibarateStill(_ sender: UIButton) {
    }
    
   
    

    // MARK: Core Motion Updates
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
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
            
            
           
        }
    }
    
    
    
    //MARK: Comm with Server
    func sendFeatures(_ array:[Double], withLabel label:CalibrationStage){
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array,
                                       "label":"\(label)",
            "dsid":self.dsid]
        
        
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
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        
                                                                        print(jsonDictionary["feature"]!)
                                                                        print(jsonDictionary["label"]!)
                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    @IBAction func getNewDsid(_ sender: UIButton) {
        // create a GET request for a new DSID from server
        let baseURL = "\(SERVER_URL)/GetNewDatasetId"
        
        let getUrl = URL(string: baseURL)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        print("Response:\n%@",response!)
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        
                                                                        // This better be an integer
                                                                        if let dsid = jsonDictionary["dsid"]{
                                                                            self.dsid = dsid as! Int
                                                                        }
                                                                    }
                                                                    
        })
        
        dataTask.resume() // start the task
    }
    
    @IBAction func doneCalibaratio(_ sender: Any) {
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
