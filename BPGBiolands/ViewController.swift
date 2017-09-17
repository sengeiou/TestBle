//
//  ViewController.swift
//  BPGBiolands
//
//  Created by starlueng on 2016/8/12.
//  Copyright © 2016年 starlueng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var  BPGPro :BPGProtocol = BPGProtocol.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BPGPro.BLEDelegate()
        let titles = ["开机","关机","开测","暂停"]
        
        for i in 0 ..< 4 {
            let button = UIButton(type:.system)
            button.frame = CGRect(x: i / 2 * 100 ,y:100 + i % 2 * 100 ,width: 100 ,height :100)
            button.setTitle(titles[i], for: .normal)
            button.addTarget(self, action: #selector(ViewController.actions(button:)), for: .touchUpInside)
            button.tag = 10 + i
            self.view.addSubview(button)
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
   @objc func actions(button:UIButton) {
    
        switch button.tag {
        case 10:
            BPGPro.turnOnModeWith(success: { (model :BPGModel?) in
                
                print("\(model)")
                }, fail: { (error :NSError?) in
                    print("\(error)")
            })
                
        case 11:
            BPGPro.turnOffModeWith(success: { (model :BPGModel?) in
                
                print("\(model)")
                }, fail: { (error :NSError?) in
                    print("\(error)")
            })
        case 12:
            BPGPro.realTestMode(success: { (model :BPGModel?) in
                
                print("\(model)")
                }, fail: { (error :NSError?) in
                    print("\(error)")
            })
        case 13:
            BPGPro.pauseMode(success: { (model :BPGModel?) in
                
                print("\(model)")
                }, fail: { (error :NSError?) in
                    print("\(error)")
            })
        default:
            break
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

