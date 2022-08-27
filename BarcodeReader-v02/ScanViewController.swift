//
//  ScanViewController.swift
//  BarcodeReader-v02
//
//  Created by 神田章博 on 2022/08/27.
//

import UIKit
import AVFoundation
import Vision

class ScanViewController: UIViewController {
    @IBOutlet weak var cameraView: UIView! //カメラ映像を映すView
    @IBOutlet weak var lightButton: UIButton!
    @IBOutlet weak var autoFocusButton: UIButton!
    @IBOutlet weak var autoFocusIcon: UIImageView!
    @IBOutlet weak var navigationTitle: UINavigationItem!
    
    private let device = AVCaptureDevice.default(for: .video)
    private var previewImageView: AVCaptureVideoPreviewLayer! = nil
    private let avCaptureSession = AVCaptureSession()
    private let focusView = UIView()
    private var resultImage = UIImage()
    private var barcodeText = ""

    
    private var cameraViewWidth:Double = 0
    private var cameraViewHeight:Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupMaskView()
        setupButtonAndView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.avCaptureSession.startRunning()
        
        //フォーカスモードを自動に戻す
        guard let device = device else {return}
        do {
            try device.lockForConfiguration()
            device.focusMode = .continuousAutoFocus // .autoForcus（固定） もしくは .continuousAutoFocus（デバイスによる自動監視継続）
            device.unlockForConfiguration()
        } catch let error {
            print(error)
        }
        self.autoFocusIcon.image = UIImage(named: "auto.focus")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationTitle.title = "読み取り中…"
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.avCaptureSession.stopRunning()
        self.lightButton.configuration?.image = UIImage(systemName: "bolt.slash")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationTitle.title = "戻る"
    }
    
    // 遷移先画面にへの値渡し
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReadResult" {
            let nextView = segue.destination as! ShowReadResultViewController
            nextView.resultImage = self.resultImage
            nextView.barcodeText = self.barcodeText
        }
    }
    /// その他レイヤとボタンのセットアップ
    private func setupButtonAndView() {
        // ライトボタンをのセットアップ
        let frameSizeRate = calcMaskFrameRange()
        
        let buttonX = cameraView.frame.width * (1 - frameSizeRate["x"]!) - 45
        let buttonY = (cameraView.frame.height * frameSizeRate["y"]!) + (cameraView.frame.width * frameSizeRate["height"]!) + 10
        self.lightButton.frame =  CGRect(x: buttonX, y: buttonY, width: 45, height: 45)
        self.cameraView.addSubview(self.lightButton)
        
        // オートフォーカスボタンのセットアップ
        //self.autoFocusButton.configuration?.image = UIImage(named: "aout.focus.slach")
        self.autoFocusButton.frame =  CGRect(x: buttonX, y: buttonY + 55, width: 45, height: 45)
        self.cameraView.addSubview(self.autoFocusButton)
        self.autoFocusIcon.frame = CGRect(x: buttonX + ((45 - 27)/2), y: buttonY + 55 + ((45 - 27)/2), width: 27, height: 27)
        self.cameraView.addSubview(self.autoFocusIcon)

        
        //focusViewの初期設定
        self.focusView.layer.borderWidth = 1
        self.focusView.layer.borderColor = UIColor.systemYellow.cgColor
        self.focusView.isHidden = true
        self.cameraView.addSubview(self.focusView)
    }
    
    /// ライトのON/OFF
    @IBAction func putLight(_ sender: Any) {
        if device!.hasTorch, device!.isTorchAvailable { // キャプチャデバイスにライトがあるか、　ライトが使用可能な状態か
            do {
                try device!.lockForConfiguration() // デバイスにアクセスするときはこれする。
                //try device!.setTorchModeOn(level: 1.0) // 点灯。明るさレベルは 0.0 ~ 1.0
            } catch let error {
                print(error)
            }
            
            if device!.isTorchActive {
                device!.torchMode = .off
                lightButton.configuration?.image = UIImage(systemName: "bolt.slash")
            } else {
                device!.torchMode = .on
                lightButton.configuration?.image = UIImage(systemName: "bolt.fill")
            }
            AudioServicesPlaySystemSound(1519)
            device!.unlockForConfiguration()
        }
    }
    
    /// オートフォーカスのON/OFF
    @IBAction func setAutoFocus(_ sender: Any) {
        guard let device = device else {return}
        if device.focusMode.rawValue == AVCaptureDevice.FocusMode.continuousAutoFocus.rawValue {
            do {
                try device.lockForConfiguration()
                device.focusMode = .autoFocus // .autoForcus（固定） もしくは .continuousAutoFocus（デバイスによる自動監視継続）
                device.unlockForConfiguration()
            } catch let error {
                print(error)
            }
            self.autoFocusIcon.image = UIImage(named: "auto.focus.slash")
        }
        else if device.focusMode.rawValue == AVCaptureDevice.FocusMode.locked.rawValue {
            do {
                try device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus // .autoForcus（固定） もしくは .continuousAutoFocus（デバイスによる自動監視継続）
                device.unlockForConfiguration()
            } catch let error {
                print(error)
            }
            self.autoFocusIcon.image = UIImage(named: "auto.focus")
        }
        AudioServicesPlaySystemSound(1519)
    }
    
    /// maskViewのセットアップ
    private func setupMaskView() {
        let frameSizeRate = calcMaskFrameRange()
        let blackView = UIView()
        blackView.frame = self.cameraView.frame
        blackView.isUserInteractionEnabled = false   //タップ無効化
        blackView.backgroundColor = .black.withAlphaComponent(0.5)
        self.cameraView.addSubview(blackView)
        
        let path = UIBezierPath (
            roundedRect: blackView.frame,
            cornerRadius: 0)
        
        let roundRectle = UIBezierPath (
            roundedRect: CGRect(x:cameraView.frame.width * frameSizeRate["x"]!,
                                y: cameraView.frame.height * frameSizeRate["y"]!,
                                width:cameraView.frame.width * frameSizeRate["width"]!,
                                height:cameraView.frame.width * frameSizeRate["height"]!),
                                cornerRadius: 22)
        
        path.append(roundRectle)
        path.usesEvenOddFillRule = true
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        blackView.layer.mask = maskLayer
        
        //image 追加
        let scanLineImg = UIImageView()
        scanLineImg.image = UIImage(named: "scan_range")
        scanLineImg.frame =  CGRect(x:cameraView.frame.width * frameSizeRate["x"]!,
                                    y: cameraView.frame.height * frameSizeRate["y"]!,
                                    width:cameraView.frame.width * frameSizeRate["width"]!,
                                    height:cameraView.frame.width * frameSizeRate["height"]!)
        
        self.cameraView.addSubview(scanLineImg)
    }
    
    /// maskViewフレームの比率計算
    private func calcMaskFrameRange() -> [String: Double] {
        let frameWidthRate:Double = 0.9 //フレーム幅の何%を検知エリアとするか
        let frameHeightRate:Double = frameWidthRate
        let frameXRate:Double = (1 - frameWidthRate) * 0.5
        let frameYRate:Double = 0.2 //フレーム高さ何%以下から検知エリアを設定するか
        
        return ["x": frameXRate, "y": frameYRate, "width": frameWidthRate, "height": frameHeightRate]
    }
    
    /// 検知エリアの比率計算関数
    private func calcDetectionRange(imgW:Double, imgH:Double) -> [String: Double] {
        let frameWidth = cameraViewWidth
        let frameHeight = cameraViewHeight
        
        let imageWidth:Double = imgW
        let imagegHeight:Double = imgH
                
        let frameSizeRate = calcMaskFrameRange()
                        
        let detectionHeight:Double = (frameWidth * frameSizeRate["width"]! * imagegHeight) / (frameHeight * imageWidth)
        let detectionY:Double = (1 - detectionHeight) * 0.5
        let detectionWidth:Double = (detectionHeight * imageWidth) / imagegHeight
        let detectionX:Double = frameSizeRate["y"]!

        return ["x": detectionX, "y": detectionY, "width": detectionWidth, "height": detectionHeight]
    }
    
    /// カメラのセットアップ
    private func setupCamera() {
        self.cameraViewWidth  = Double(self.cameraView.frame.width)
        self.cameraViewHeight  = Double(self.cameraView.frame.height)

        self.avCaptureSession.sessionPreset = .photo
 
        let input = try! AVCaptureDeviceInput(device: device!)
        self.avCaptureSession.addInput(input)
 
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: .global())
        
        self.avCaptureSession.addOutput(videoDataOutput)
        self.avCaptureSession.startRunning()
        
        self.previewImageView = AVCaptureVideoPreviewLayer(session: self.avCaptureSession)
        self.previewImageView.backgroundColor = UIColor.clear.cgColor
        self.previewImageView.videoGravity = .resizeAspectFill
        self.previewImageView.frame = cameraView.frame
        let rootLayer = self.cameraView.layer
        rootLayer.masksToBounds = true
        rootLayer.addSublayer(self.previewImageView)
     }

    /// コンテキストに矩形を描画
    private func drawRect(_ rect: CGRect, context: CGContext) {
        context.setLineWidth(4.0)
        context.setStrokeColor(UIColor.green.cgColor)
        context.stroke(rect)
    }
    
    /// バーコード認識情報の配列取得 (非同期)
    private func getBarcodeObservations(pixelBuffer: CVPixelBuffer, completion: @escaping (([VNBarcodeObservation])->())) {
        let request = VNDetectBarcodesRequest { (request, error) in
            guard let results = request.results as? [VNBarcodeObservation] else {
                completion([])
                return
            }
            completion(results)
        }
        let detectionRange = calcDetectionRange(imgW: Double(CVPixelBufferGetHeight(pixelBuffer)), imgH: Double(CVPixelBufferGetWidth(pixelBuffer)))
        request.regionOfInterest = CGRect(x: detectionRange["x"]!,
                                          y: detectionRange["y"]!,
                                          width: detectionRange["width"]!,
                                          height: detectionRange["height"]!)
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    /// 正規化された矩形位置を指定領域に展開
    /// 検知範囲に応じてtargetSizeの倍率を変えてあげる必要あり
    private func getUnfoldRect(normalizedRect: CGRect, targetSize: CGSize) -> CGRect {
        let detectionRange = calcDetectionRange(imgW: Double(targetSize.height), imgH: Double(targetSize.width))
        return CGRect(
            x: (normalizedRect.minX * targetSize.width * detectionRange["width"]!) + (targetSize.width * detectionRange["x"]!),
            y: (normalizedRect.minY * targetSize.height * detectionRange["height"]!) + (targetSize.height * detectionRange["y"]!),
            width: normalizedRect.width * targetSize.width * detectionRange["width"]!,
            height: normalizedRect.height * targetSize.height * detectionRange["height"]!
        )
    }
    
    /// バーコード検出位置に矩形を描画した image を取得
    private func getBarcodeRectsImage(sampleBuffer :CMSampleBuffer, barcodeObservations: [VNBarcodeObservation]) -> UIImage? {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        guard let pixelBufferBaseAddres = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
            
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bitmapInfo = CGBitmapInfo(rawValue:
            (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        )

        guard let newContext = CGContext(
            data: pixelBufferBaseAddres,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
            ) else
        {
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }

        let imageSize = CGSize(width: width, height: height)
        let barcodeRects = barcodeObservations.compactMap {
            getUnfoldRect(normalizedRect: $0.boundingBox, targetSize: imageSize)
        }
        self.drawRect(barcodeRects[0], context: newContext)

        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        guard let imageRef = newContext.makeImage() else {
            return nil
        }
        let image = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImage.Orientation.right)
        
        
        // barcodeText
        self.barcodeText = (barcodeObservations.first?.payloadStringValue)!

        return image
    }

    //画像を検知エリアでトリミング
    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
        let imgRef = image.cgImage?.cropping(to: trimmingArea)
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        return trimImage
    }
    
    /*=============================
     ===カメラタップ時のフォーカス設定===
     ==============================**/
    //タップ時にcameraViewの座標を取得しフォーカスを合わせる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //sessionがrunningの時のみ処理
        if avCaptureSession.isRunning {
            guard let touch = touches.first else{return}
                        
            //View内のタップ座標を、AVCapturePreviewLayer内の座標（０〜１）に正規化
            let pointInView = touch.location(in: cameraView)
            print(pointInView)
            let pointInCamera = previewImageView?.captureDevicePointConverted(fromLayerPoint: pointInView)
            print(pointInCamera!)
            
            //取得した座標にフォーカスを合わせる
            guard let device = device else {return}
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = pointInCamera!
                device.focusMode = .autoFocus // .autoForcus（固定） もしくは .continuousAutoFocus（デバイスによる自動監視継続）
                device.unlockForConfiguration()
                
            } catch let error {
                print(error)
            }
            //autoFocusButtonのイメージを変える
            self.autoFocusIcon.image = UIImage(named: "auto.focus.slash")

            //focusViewの表示とアニメーション
            self.focusView.frame = CGRect(x: pointInView.x - (self.view.bounds.width * 0.3)/2,
                                          y: pointInView.y - (self.view.bounds.width * 0.3)/2,
                                          width: view.bounds.width * 0.3,
                                          height: view.bounds.width * 0.3)// タップしたポイントへ移動する
            self.focusView.isHidden = false

            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0, options: [],animations:{
                self.focusView.frame = CGRect(x: pointInView.x - (self.view.bounds.width * 0.075),
                                              y: pointInView.y - (self.view.bounds.width * 0.075),
                                              width: (self.view.bounds.width * 0.15),
                                              height: (self.view.bounds.width * 0.15)) // タップしたポイントに向けて縮む
            }, completion: { (UIViewAnimatingPosition) in
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (Timer) in
                    self.focusView.isHidden = true // 少し待ってから消える
                }
            })

        }
    }
    //フォーカス設定処理を記載 ここまで

}
extension ScanViewController : AVCaptureVideoDataOutputSampleBufferDelegate{
    /// カメラからの映像取得デリゲート
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        getBarcodeObservations(pixelBuffer: pixelBuffer) { [weak self] barcodeObservations in
            guard let self = self else { return }

            if !barcodeObservations.isEmpty {
                let image = self.getBarcodeRectsImage(sampleBuffer: sampleBuffer, barcodeObservations: barcodeObservations)
                self.avCaptureSession.stopRunning()
                AudioServicesPlaySystemSound(1519)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let image = image else {return}
//                    let detectionRange = self?.calcDetectionRange(imgW: Double(image.size.width), imgH: Double(image.size.height))
//                    let trimmingedImage = self?.trimmingImage(image, trimmingArea: CGRect(x: image.size.height * detectionRange!["x"]!,
//                                                                                          y: image.size.width * detectionRange!["y"]!,
//                                                                                          width: image.size.height * detectionRange!["width"]!,
//                                                                                          height: image.size.width * detectionRange!["height"]!))
                    self?.resultImage = image
//                    self?.outputImageView.image = trimmingedImage
//                    self?.outputImageView.contentMode = .scaleAspectFit

                    //image 追加
//                    let barcodeImageView = UIImageView()
//                    barcodeImageView.image = image
//                    barcodeImageView.frame = (self?.cameraView.frame)!
//                    barcodeImageView.contentMode = .scaleAspectFill
//                    self?.cameraView.addSubview(barcodeImageView)
//                    self?.setupMaskView()
                    self?.performSegue(withIdentifier: "showReadResult", sender: nil)
                    print("count")
                    }
            }
        }
    }
}

