//
//  ViewController.swift
//  BarcodeReader-v02
//
//  Created by 神田章博 on 2022/06/25.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var navigationLabel: UINavigationItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    // UIImagePickerController カメラを起動する
    //  - Parameter sender: "UIImagePickerController"ボタン
    
    @IBAction func startUiImagePickerControlle(_ sender: Any) {
        navigationLabel.title = "Scanning…"
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        // UIImagePickerController カメラを起動する
        present(picker, animated: true, completion: nil)
        
        
        print("\(navigationLabel.title!) ddddd")
        
//        let detectBarcodeRequest = VNDetectBarcodesRequest()
//        detectBarcodeRequest.revision = VNDetectBarcodesRequestRevision2
//        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
//        do {
//            try handler.perform([detectBarcodeRequest])
//            guard let observations = detectBarcodeRequest.results as? [VNBarcodeObservation] else { return }
//        } catch {
//            print("Vision error: \(error.localizedDescription)")
//        }
    }
    
}

