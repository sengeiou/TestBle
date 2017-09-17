//
//  BPGModel.swift
//  BPG-Bioland
//
//  Created by starlueng on 2016/8/13.
//  Copyright © 2016年 starlueng. All rights reserved.
//

import Foundation

class BPGModel:AnyObject{
    
    var head :UInt8 ,cmd :UInt8 ,status :UInt8 ,leng :UInt16 ,body :[UInt8]?,checkcs :UInt8 ,end :UInt8
    
    init() {
        
        head  = 0 ;cmd  = 0; status = 0; leng  = 0; checkcs = 0 ;end  = 0
    }
    
}