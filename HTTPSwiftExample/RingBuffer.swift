//
//  RingBuffer.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 10/27/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

import UIKit

var BUFFER_SIZE = 50

class RingBuffer: NSObject {
    var size:Int
    lazy var x = [Double](repeating:0, count:size)
    lazy var y = [Double](repeating:0, count:size)
    lazy var z = [Double](repeating:0, count:size)
    
    init(withSize size:Int) {
        self.size = size
    }
    
    var head:Int = 0 {
        didSet{
            if(head >= self.size){
                head = 0
            }
            
        }
    }
    
    
    func addNewData(xData:Double,yData:Double,zData:Double){
        x[head] = xData
        y[head] = yData
        z[head] = zData
        
        head += 1
    }
    
    func getDataAsVector()->[Double]{
        var allVals = [Double](repeating:0, count:3*self.size)
        
        for i in 0..<self.size {
            let idx = (head+i)%self.size
            allVals[3*i] = x[idx]
            allVals[3*i+1] = y[idx]
            allVals[3*i+2] = z[idx]
        }
        
        return allVals
    }

}
