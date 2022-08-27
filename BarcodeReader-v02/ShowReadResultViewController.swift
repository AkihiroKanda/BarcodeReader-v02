//
//  showReadResultViewController.swift
//  BarcodeReader-v02
//
//  Created by 神田章博 on 2022/08/28.
//

import UIKit

class ShowReadResultViewController: UIViewController {
    @IBOutlet weak var barcodeTextField: UITextField!
    @IBOutlet weak var stackView: UIStackView!
    
    var resultImage = UIImage()
    var barcodeText = "";

    override func viewDidLoad() {
        super.viewDidLoad()
        let barcodeImageView = UIImageView()
        barcodeImageView.image = resultImage
        barcodeImageView.frame = self.view.frame
        barcodeImageView.contentMode = .scaleAspectFill
        self.view.addSubview(barcodeImageView)
        setupMaskView()
        
        self.view.addSubview(stackView)

        barcodeTextField.text = barcodeText
    }
    

    /// maskViewのセットアップ
    private func setupMaskView() {
        let frameSizeRate = calcMaskFrameRange()
        let blackView = UIVisualEffectView (effect: UIBlurEffect (style: UIBlurEffect.Style.systemUltraThinMaterialDark))
        blackView.frame = self.view.frame
        blackView.isUserInteractionEnabled = false   //タップ無効化
        blackView.backgroundColor = .black.withAlphaComponent(0.5)
        self.view.addSubview(blackView)
        
        let path = UIBezierPath (
            roundedRect: blackView.frame,
            cornerRadius: 0)
        
        let roundRectle = UIBezierPath (
            roundedRect: CGRect(x:self.view.frame.width * frameSizeRate["x"]!,
                                y: self.view.frame.height * frameSizeRate["y"]!,
                                width:self.view.frame.width * frameSizeRate["width"]!,
                                height:self.view.frame.width * frameSizeRate["height"]!),
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
        scanLineImg.frame =  CGRect(x:self.view.frame.width * frameSizeRate["x"]!,
                                    y: self.view.frame.height * frameSizeRate["y"]!,
                                    width:self.view.frame.width * frameSizeRate["width"]!,
                                    height:self.view.frame.width * frameSizeRate["height"]!)
        
        self.view.addSubview(scanLineImg)
    }
    
    /// maskViewフレームの比率計算
    private func calcMaskFrameRange() -> [String: Double] {
        let frameWidthRate:Double = 0.9 //フレーム幅の何%を検知エリアとするか
        let frameHeightRate:Double = frameWidthRate
        let frameXRate:Double = (1 - frameWidthRate) * 0.5
        let frameYRate:Double = 0.2 //フレーム高さ何%以下から検知エリアを設定するか
        
        return ["x": frameXRate, "y": frameYRate, "width": frameWidthRate, "height": frameHeightRate]
    }

}
