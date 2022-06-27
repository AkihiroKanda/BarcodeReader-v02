//
//  ViewController.swift
//  BarcodeReader-v02
//
//  Created by 神田章博 on 2022/06/25.
//

import UIKit
import AVFoundation
import Vision
import AudioToolbox

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    private var textLayer: CATextLayer! = nil
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private var handler = VNSequenceRequestHandler()
    private var currentTarget: VNDetectedObjectObservation?
    private var lockOnLayer = CALayer()
    
    @IBOutlet weak var navigationLabel: UINavigationItem!
    @IBOutlet weak var outputBarcodeNumberLabel: UILabel!
    @IBOutlet weak var scanControlButton: UIButton!
    
    //scan controlボタンのタイトル設定
    let scanControlButtonTitle = ["Start Scan!","Stop Scan"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //ボタンのテキスト設定
        self.scanControlButton.setTitle(scanControlButtonTitle[0], for: .normal)

        //読み取り結果表示のラベルを非表示に設定
        self.outputBarcodeNumberLabel.isHidden = true
        
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //ボタンのテキスト設定
        self.scanControlButton.setTitle(scanControlButtonTitle[0], for: .normal)
        self.navigationLabel.title = "BarcodeReader"
        //self.session.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.session.stopRunning()
    }
    
    private func setup() {
        setupVideoProcessing()
        setupCameraPreview()
        setupTextLayer()
    }
    
    private func setupVideoProcessing() {
        self.session.sessionPreset = .photo

        let device = AVCaptureDevice.default(for: .video)
        let input = try! AVCaptureDeviceInput(device: device!)
        self.session.addInput(input)

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: .global())
        self.session.addOutput(videoDataOutput)
    }

    private func setupCameraPreview() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.backgroundColor = UIColor.clear.cgColor
        self.previewLayer.videoGravity = .resizeAspectFill
        let rootLayer = self.view.layer
        rootLayer.masksToBounds = true
        //カメラサイズ指定
        //self.previewLayer.frame = rootLayer.bounds
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: 375, height: 425)
        rootLayer.addSublayer(self.previewLayer)
    }

    private func setupTextLayer() {
        let textLayer = CATextLayer()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 20
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 24)
        textLayer.cornerRadius = 4
        textLayer.backgroundColor = UIColor(white: 0.25, alpha: 0.5).cgColor
        //バーコードデータテキストの表示位置指定
        textLayer.position = CGPoint(x:self.view.bounds.width/2,y:200)
        textLayer.isHidden = true
        self.previewLayer.addSublayer(textLayer)
        self.textLayer = textLayer
    }

    private func handleBarcodes(request: VNRequest, error: Error?) {
        guard let barcode = request.results?.first as? VNBarcodeObservation else {
            DispatchQueue.main.async {
                self.textLayer.isHidden = true
            }
            return
        }

        if let value = barcode.payloadStringValue {
            DispatchQueue.main.async {
                self.textLayer.string = value
                self.textLayer.isHidden = false
                self.outputBarcodeNumberLabel.text = value
                self.outputBarcodeNumberLabel.isHidden = false
                AudioServicesPlaySystemSound(1520) //バーコード検知でバイブレーション通知
                
                self.scanControlButton.setTitle(self.scanControlButtonTitle[0], for: .normal)
                self.navigationLabel.title = "BarcodeReader"
                self.session.stopRunning()

            }
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let handler = VNSequenceRequestHandler()
        let barcodesDetectionRequest = VNDetectBarcodesRequest(completionHandler: self.handleBarcodes)

        try? handler.perform([barcodesDetectionRequest], on: pixelBuffer)
    }
    
    
    // UIImagePickerController カメラを起動する
    //  - Parameter sender: "UIImagePickerController"ボタン
    
    @IBAction func startUiImagePickerControlle(_ sender: Any) {
        //ボタンテキストが”Start scan！の時の処理”
        if self.scanControlButton.currentTitle == scanControlButtonTitle[0] {
            self.scanControlButton.setTitle(scanControlButtonTitle[1], for: .normal)
            self.navigationLabel.title = "Scanning…"
            self.outputBarcodeNumberLabel.text = ""
            self.session.startRunning()
            
        }else if self.scanControlButton.currentTitle == scanControlButtonTitle[1]{
            self.scanControlButton.setTitle(scanControlButtonTitle[0], for: .normal)
            self.navigationLabel.title = "BarcodeReader"
            self.session.stopRunning()
        }
        
    }
}
