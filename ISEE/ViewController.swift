//
//  ViewController.swift
//  ISEE
//
//  Created by 森杏菜 on 2023/12/25.
//



import UIKit
import AVFoundation
import CoreImage.CIFilterBuiltins

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet var visionButtons: [UIButton]!
    
    
    var captureSesssion = AVCaptureSession()
    var videoOutput = AVCaptureVideoDataOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    override func viewWillAppear(_ animated: Bool) {
        setupButtons()
        setupCamera()
    }
    
    func setupButtons(){
        visionButtons.forEach { button in
            let happy = UIColor(red: 0/255, green: 83/255, blue: 245/255, alpha: 0.8).cgColor
            button.setTitle(ColorBlindType(rawValue: button.tag)!.name, for:  .normal)
            button.layer.cornerRadius = 18
            button.layer.borderColor = happy
            button.layer.borderWidth = 2
        }
    }
    
    func setupCamera(){
        captureSesssion.sessionPreset = .hd1920x1080 // 解像度の設定
        
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            // 入力
            if (captureSesssion.canAddInput(input)) {
                captureSesssion.addInput(input)
            }
            // 出力
            videoOutput.setSampleBufferDelegate(self, queue: .main)
            if captureSesssion.canAddOutput(videoOutput) {
                captureSesssion.addOutput(videoOutput)
            }
            
            DispatchQueue.global(qos: .background).async {
                self.captureSesssion.startRunning()
            }// カメラ起動
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
            previewLayer.frame = cameraView.bounds
            previewLayer.videoGravity = .resizeAspectFill // アスペクトフィット
            previewLayer.connection?.videoOrientation = .portrait // カメラの向き
            
            cameraView.layer.addSublayer(previewLayer)
        }
        catch {
            print(error)
        }
    }
    var filter: CIFilter & CIColorMatrix = {
        let filter = CIFilter.colorMatrix()
        filter.rVector = CIVector(x: 1, y: 0, z: 0, w: 0)
        filter.gVector = CIVector(x: 0, y: 1, z: 0, w: 0)
        filter.bVector = CIVector(x: 0, y: 0, z: 1, w: 0)
        return filter
    }()
    
    
    func setBlindType(_ blindType: ColorBlindType) {
        let vectors = blindType.vectors
        filter.rVector = vectors[0]
        filter.gVector = vectors[1]
        filter.bVector = vectors[2]
    }
    
    @IBAction func didTapVisionButton(_ sender: UIButton){
        setBlindType(ColorBlindType(rawValue: sender.tag)!)
        visionButtons.forEach { button in
            button.backgroundColor = UIColor(named: "buttonColor")
            button.isEnabled = true
            button.setTitleColor(UIColor(red: 0/255, green: 83/255, blue: 245/255, alpha: 0.8), for: .normal)
        }
        sender.backgroundColor = UIColor(red: 0/255, green: 83/255, blue: 245/255, alpha: 0.8)
        sender.isEnabled = false
        
        sender.setTitleColor(.white, for: .normal)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        cameraImage = cameraImage.transformed(by: cameraImage.orientationTransform(for: .right))
        
        filter.inputImage = cameraImage
        
        let cgImage = CIContext().createCGImage(filter.outputImage!, from: cameraImage.extent)!
        DispatchQueue.main.async {
            let filteredImage = UIImage(cgImage: cgImage)
            self.imageView.image = filteredImage
        }
    }
    
    
}


enum ColorBlindType: Int {
    case normal = 0
    case protanopia = 1
    case deuteranopia = 2
    case tritanopia = 3
    
    var name: String {
        switch self {
        case .normal:
            "正常色覚"
        case .protanopia:
            "1型2色覚"
        case .deuteranopia:
            "2型2色覚"
        case .tritanopia:
            "3型2色覚"
        default:
            "未設定"
        }
    }
    
    var vectors: [CIVector] {
        switch self {
        case .normal:
            return [
                CIVector(x: 1, y: 0, z: 0, w: 0),
                CIVector(x: 0, y: 1, z: 0, w: 0),
                CIVector(x: 0, y: 0, z: 1, w: 0)
            ]
        case .protanopia:
            return [
                CIVector(x: 0.56667, y: 0.43333, z: 0, w: 0),
                CIVector(x: 0.55833, y: 0.44167, z: 0, w: 0),
                CIVector(x: 0, y: 0.24167, z: 0.75833, w: 0)
            ]
        case .deuteranopia:
            return [
                CIVector(x: 0.625, y: 0.375, z: 0, w: 0),
                CIVector(x: 0.7, y: 0.3, z: 0, w: 0),
                CIVector(x: 0, y: 0.3, z: 0.7, w: 0)
            ]
        case .tritanopia:
            return [
                CIVector(x: 0.95, y: 0.05, z: 0, w: 0),
                CIVector(x: 0, y: 0.43, z: 0.56, w: 0),
                CIVector(x: 0, y: 0.4755, z: 0.525, w: 0)
            ]
        }
    }
}
