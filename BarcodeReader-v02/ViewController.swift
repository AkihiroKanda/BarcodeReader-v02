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
    
    
    private let barCodeImage = UIImage(named: "sampleBarcode")
    @IBOutlet weak var navigationLabel: UINavigationItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var outputBarcodeNumberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        outputBarcodeNumberLabel.text = ""
    }
    
    
    
    
    // UIImagePickerController カメラを起動する
    //  - Parameter sender: "UIImagePickerController"ボタン
    
    @IBAction func startUiImagePickerControlle(_ sender: Any) {
        navigationLabel.title = "Scanning…"
        
        faceDetection()
        
//        let picker = UIImagePickerController()
//        picker.sourceType = .camera
//        picker.delegate = self
//        // UIImagePickerController カメラを起動する
//        present(picker, animated: true, completion: nil)
        
        
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
    
    
    func faceDetection() {
        let request = VNDetectBarcodesRequest { (request, error) in
            var image = self.barCodeImage
            for observation in request.results as! [VNBarcodeObservation] {
                image = self.drawFaceRectangle(image: image, observation: observation)
            }
            self.imageView.image = image
        }

        if let cgImage = self.barCodeImage?.cgImage {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
        
        
        guard let barcode = request.results?.first as? VNBarcodeObservation else {
            DispatchQueue.main.async {
                self.outputBarcodeNumberLabel.isHidden = true
            }
            return
        }

        if let value = barcode.payloadStringValue {
            DispatchQueue.main.async {
                self.outputBarcodeNumberLabel.text = value
                self.outputBarcodeNumberLabel.isHidden = false
            }
        }
        
    }
    private func drawFaceRectangle(image: UIImage?, observation: VNBarcodeObservation) -> UIImage? {
        let imageSize = image!.size
 
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        image?.draw(in: CGRect(origin: .zero, size: imageSize))
        context?.setLineWidth(4.0)
        context?.setStrokeColor(UIColor.green.cgColor)
        context?.stroke(observation.boundingBox.converted(to: imageSize))
        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return drawnImage
    }
    
}
extension CGRect {
    func converted(to size: CGSize) -> CGRect {
        return CGRect(x: self.minX * size.width,
                      y: (1 - self.maxY) * size.height,
                      width: self.width * size.width,
                      height: self.height * size.height)
    }
}

