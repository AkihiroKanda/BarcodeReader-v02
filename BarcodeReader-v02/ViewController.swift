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
    private let device = AVCaptureDevice.default(for: .video)
    private var focusView = UIView()
    
    @IBOutlet weak var navigationLabel: UINavigationItem!
    @IBOutlet weak var scanControlButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var barcodeDataText: UITextField!
    @IBOutlet weak var buttomStackView: UIStackView!
    @IBOutlet weak var cameraView: UIView!
    
    //scan controlボタンのタイトル設定
    let scanControlButtonTitle = ["読み取り開始","停止"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 常にライトモード（明るい外観）を指定することでダークモード適用を回避
        self.overrideUserInterfaceStyle = .light
        
        //ボタンのテキスト設定
        scanControlButton.setTitle(scanControlButtonTitle[0], for: .normal)
        scanControlButton.contentHorizontalAlignment = .center
        
        //テキストフィールドの設定　キーボード表示
        self.barcodeDataText.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        //コピーボタンと検索ボタンを無効化
        copyButton.isEnabled = false
        shareButton.isEnabled = false
        searchButton.isEnabled = false
        
        setup()
        //ここから
        //        var config = UIButton.Configuration.filled()
        //        config.title = "Start"
        //        config.cornerStyle = .capsule
        //        config.titleAlignment = .center
        //
        //        config.image = UIImage(systemName: "camera.fill",
        //                               withConfiguration: UIImage.SymbolConfiguration(scale: .large))
        //        //config.imagePlacement = .trailing
        //        config.imagePadding = 8.0
        //
        //        var container = AttributeContainer()
        //        container.font = UIFont(name: "Helvetica", size: 50)
        //        config.attributedTitle = AttributedString("Button", attributes: container)
        //
        //        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        //            var outgoing = incoming
        //            outgoing.font = UIFont(name: "Helvetica", size: 50)
        //            return outgoing
        //        }
        //
        //        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 42.0))
        //        sampleButton.configuration = config
        //
        //        scanControlButton.imageView?.contentMode = .scaleAspectFill
        //        scanControlButton.contentHorizontalAlignment = .fill
        //        scanControlButton.contentVerticalAlignment = .fill
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //テキストフィールドの設定　キーボード表示
        self.barcodeDataText.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        //ボタンのテキスト設定
        self.scanControlButton.setTitle(scanControlButtonTitle[0], for: .normal)
        self.scanControlButton.configuration?.baseBackgroundColor = .systemOrange
        self.scanControlButton.configuration?.image = UIImage(systemName: "barcode.viewfinder")
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
        
        //let device = AVCaptureDevice.default(for: .video)
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
        let rootLayer = self.cameraView.layer
        rootLayer.masksToBounds = true
        //カメラサイズ指定
        self.previewLayer.frame = rootLayer.bounds
        //self.previewLayer.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 225)
        rootLayer.addSublayer(self.previewLayer)
        self.view.bringSubviewToFront(self.buttomStackView)
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
        
        //focusViewの初期設定
        focusView.layer.borderWidth = 1
        focusView.layer.borderColor = UIColor.systemYellow.cgColor
        focusView.isHidden = true
        self.previewLayer.addSublayer(focusView.layer)
    }
    
    private func handleBarcodes(request: VNRequest, error: Error?) {
        guard let barcode = request.results?.first as? VNBarcodeObservation else {return}
        
        if let value = barcode.payloadStringValue {
            DispatchQueue.main.async {
                self.textLayer.string = value
                self.textLayer.isHidden = false
                self.barcodeDataText.text = value
                
                AudioServicesPlaySystemSound(1520) //バーコード検知でバイブレーション通知
                
                self.scanControlButton.setTitle(self.scanControlButtonTitle[0], for: .normal)
                self.scanControlButton.configuration?.baseBackgroundColor = .systemOrange
                self.scanControlButton.configuration?.image = UIImage(systemName: "barcode.viewfinder")
                self.navigationLabel.title = "BarcodeReader"
                
                //コピーボタンと検索ボタンを有効化
                self.copyButton.isEnabled = true
                self.shareButton.isEnabled = true
                self.searchButton.isEnabled = true
                
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
            self.scanControlButton.configuration?.baseBackgroundColor = .red
            self.scanControlButton.configuration?.image = UIImage(systemName: "stop.circle")
            self.navigationLabel.title = "Scanning…"
            self.barcodeDataText.text = ""
            //コピーボタンと検索ボタンを無効化
            self.copyButton.isEnabled = false
            self.shareButton.isEnabled = false
            self.searchButton.isEnabled = false
            //読み取り結果のテキストレイヤを非表示
            self.textLayer.isHidden = true
            self.session.startRunning()
            
            //カメラのフォーカス設定（デバイスによる自動監視継続に設定）
            guard let device = device else {return}
            do {
                try device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus // .autoForcus（固定） もしくは .continuousAutoFocus（デバイスによる自動監視継続）
                device.unlockForConfiguration()
                
            } catch let error {
                print(error)
            }
            
        }else if self.scanControlButton.currentTitle == scanControlButtonTitle[1]{
            self.scanControlButton.setTitle(scanControlButtonTitle[0], for: .normal)
            self.scanControlButton.configuration?.baseBackgroundColor = .systemOrange
            self.scanControlButton.configuration?.image = UIImage(systemName: "barcode.viewfinder")
            self.navigationLabel.title = "BarcodeReader"
            self.session.stopRunning()
        }
        
    }
    
    //テキストフィールドの空白検知
    @IBAction func detectBlank(_ sender: Any) {
        print("空白判定：\(barcodeDataText.state.isEmpty)")
        
        if let text = barcodeDataText.text, text.isEmpty {
            //コピーボタンと検索ボタンを無効化
            self.copyButton.isEnabled = false
            self.shareButton.isEnabled = false
            self.searchButton.isEnabled = false
        } else {
            //コピーボタンと検索ボタンを有効化
            self.copyButton.isEnabled = true
            self.shareButton.isEnabled = true
            self.searchButton.isEnabled = true
        }
    }
    //コピーボタンが押された時の処理
    @IBAction func copyBarcodeNumber(_ sender: Any) {
        guard let copyText = barcodeDataText.text else {return}
        UIPasteboard.general.string = copyText
        AudioServicesPlaySystemSound(1519)
    }
    
    //共有ボタンが押された時の処理
    @IBAction func shareBarcodeData(_ sender: Any) {
        guard let shareText = barcodeDataText.text else {return}
        let shareItems = [shareText] as [Any]
        let controller = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        present(controller, animated: true, completion: nil)
        
        //        let image: UIImage = getImage(self.previewLayer)
        //        let shareItems = [image,text] as [Any]
    }
    
    
    //検索ボタンが押された時の処理
    @IBAction func serchInternet(_ sender: Any) {
        var searchUrl = "https://www.google.com/search?q="
        
        if let urlText = barcodeDataText.text{
            guard let url = URL(string: urlText) else {
                searchUrl += urlText.urlEncoded
                UIApplication.shared.open(URL(string: searchUrl)!)
                return
            }
            //URLを開く
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            else {
                searchUrl += urlText.urlEncoded
                UIApplication.shared.open(URL(string: searchUrl)!)
            }
        }
    }
    
    // UIViewからUIImageに変換する
    func getImage(_ view : UIView) -> UIImage {
        
        // キャプチャする範囲を取得する
        let rect = view.bounds
        
        // ビットマップ画像のcontextを作成する
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context : CGContext = UIGraphicsGetCurrentContext()!
        
        // view内の描画をcontextに複写する
        view.layer.render(in: context)
        
        // contextのビットマップをUIImageとして取得する
        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // contextを閉じる
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /*=============================
     ===カメラタップ時のフォーカス設定===
     ==============================**/
    //タップ時にcameraViewの座標を取得しフォーカスを合わせる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //sessionがrunningの時のみ処理
        if(session.isRunning){
            guard let touch = touches.first else{return}
            
            //View内のタップ座標を、AVCapturePreviewLayer内の座標（０〜１）に正規化
            let pointInView = touch.location(in: cameraView)
            print(pointInView)
            let pointInCamera = previewLayer?.captureDevicePointConverted(fromLayerPoint: pointInView)
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
            
            //focusViewの表示とアニメーション
            focusView.frame = CGRect(x: pointInView.x - (self.view.bounds.width * 0.3)/2, y: pointInView.y - (self.view.bounds.width * 0.3)/2, width: view.bounds.width * 0.3, height: view.bounds.width * 0.3)// タップしたポイントへ移動する
            focusView.isHidden = false

            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0, options: [],animations:{
                self.focusView.frame = CGRect(x: pointInView.x - (self.view.bounds.width * 0.075), y: pointInView.y - (self.view.bounds.width * 0.075), width: (self.view.bounds.width * 0.15), height: (self.view.bounds.width * 0.15)) // タップしたポイントに向けて縮む
            }, completion: { (UIViewAnimatingPosition) in
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (Timer) in
                    self.focusView.isHidden = true // 少し待ってから消える
                }
            })

        }
    }
    //フォーカス設定処理を記載 ここまで

    /*=============================
     ===キーボード表示非表示処理を記載===
     ==============================**/
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            } else {
                let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                self.view.frame.origin.y -= suggestionHeight
            }
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    //キーボード表示非表示処理を記載 ここまで
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}

//StringをURLエンコードする
extension String {
    var urlEncoded: String {
        // 半角英数字 + "/?-._~" のキャラクタセットを定義
        let charset = CharacterSet.alphanumerics.union(.init(charactersIn: "/?-._~"))
        // 一度すべてのパーセントエンコードを除去(URLデコード)
        let removed = removingPercentEncoding ?? self
        // あらためてパーセントエンコードして返す
        return removed.addingPercentEncoding(withAllowedCharacters: charset) ?? removed
    }
}
