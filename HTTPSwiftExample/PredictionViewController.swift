//
//  PredictionViewController.swift
//  HTTPSwiftExample
//
//  Created by Gabriel I Leyva Merino on 11/9/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

import Foundation
import UIKit

class PredictionViewController: UIViewController {
    
    //MARK: UI Elements
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    override func viewDidLoad() {
        self.prepareLabel()
        self.prepareImageView()
    }
    
    func prepareLabel() {
        predictionLabel.text = "Still"
        predictionLabel.textColor = .newOrange
    }
    
    func prepareImageView() {
        imageView.image = imageView.image!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .newOrange
    }
    
}
