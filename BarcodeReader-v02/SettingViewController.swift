//
//  SettingViewController.swift
//  BarcodeReader-v02
//
//  Created by 神田章博 on 2022/08/01.
//

import UIKit

class SettingViewController: UIViewController {

    @IBOutlet var testView: UIView!
    
    //@IBOutlet weak var forcusView: UIView!
    var forcusView = CALayer()
    
    var testLayer: CALayer {
        return testView.layer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        forcusView.frame = CGRect(x: 100, y: 100, width: view.bounds.width * 0.3, height: view.bounds.width * 0.3)
        forcusView.borderWidth = 1
        forcusView.borderColor = UIColor.systemYellow.cgColor
        forcusView.backgroundColor = UIColor.systemYellow.cgColor
        forcusView.isHidden = false
        //testLayer.addSubview(forcusView)
        self.view.layer.addSublayer(forcusView)

        //self.view.bringSubviewToFront(forcusView)
        //self.testView.addSublayer(self.focusView)
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else{return}
        
        let pointInView = touch.location(in: testView)
        print(pointInView)
//        let pointInCamera = previewLayer?.captureDevicePointConverted(fromLayerPoint: pointInView)
//        print(pointInCamera!)
        
        
        
        //focusViewの表示
        forcusView.frame = CGRect(x: pointInView.x - (self.view.bounds.width * 0.3)/2, y: pointInView.y - (self.view.bounds.width * 0.3)/2, width: view.bounds.width * 0.3, height: view.bounds.width * 0.3)// タップしたポイントへ移動する
        forcusView.isHidden = false

        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1, delay: 0, options: [],animations:{
            self.forcusView.frame = CGRect(x: pointInView.x - (self.view.bounds.width * 0.075), y: pointInView.y - (self.view.bounds.width * 0.075), width: (self.view.bounds.width * 0.15), height: (self.view.bounds.width * 0.15)) // タップしたポイントに向けて縮む
        }, completion: { (UIViewAnimatingPosition) in
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (Timer) in
                self.forcusView.isHidden = true // 少し待ってから消える
            }
        })
    }

}
