//
//  ViewController.swift
//  Demo-Camera
//
//  Created by Anand on 3/21/18.
//  Copyright © 2018 Virtual Dusk. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    
    var captureSesssion = AVCaptureSession()
    var cameraOutput  = AVCapturePhotoOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var previewView: UIView!{
        didSet{
            previewView.layer.cornerRadius = previewView.frame.size.height / 2
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setup your camera here...
        askPermission()
    }
    
    func startCamera(){
        captureSesssion.sessionPreset = AVCaptureSession.Preset.photo
        
        let device = AVCaptureDevice.default( .builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        
        if let input = try? AVCaptureDeviceInput(device: device!) {
            if (captureSesssion.canAddInput(input)) {
                captureSesssion.addInput(input)
                if (captureSesssion.canAddOutput(cameraOutput)) {
                    captureSesssion.addOutput(cameraOutput)
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
                    previewLayer.connection?.videoOrientation = .portrait
                    previewLayer.videoGravity = .resizeAspectFill;
                    previewLayer.frame = previewView.bounds
                    previewView.clipsToBounds = true
                    previewView.layer.addSublayer(previewLayer)
                    captureSesssion.startRunning()
                }
            } else {
                print("issue here : captureSesssion.canAddInput")
            }
        } else {
            print("some problem here")
        }
    }
    
    @IBAction func actionTakePhotos(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    
    // callBack from take picture
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            print("error occure : \(error.localizedDescription)")
            return
        }
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: .right)
            self.capturedImage.image = image
            self.previewView.bringSubview(toFront: self.capturedImage)
        } else {
            print("some error here")
        }
    }
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("error occure : \(error.localizedDescription)")
            return
        }
        let imageData = photo.fileDataRepresentation()
        let dataProvider = CGDataProvider(data: imageData! as CFData)
        let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: .right)
        self.capturedImage.image = image
        self.previewView.bringSubview(toFront: self.capturedImage)
    }
    
    // This method you can use somewhere you need to know camera permission   state
    func askPermission() {
        let cameraPermissionStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraPermissionStatus {
        case .authorized:
            print("Already Authorized")
            startCamera()
        case .denied:
            print("denied")
            
            let alert = UIAlertController(title: "Sorry :(" , message: "But  could you please grant permission for camera within device settings",  preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .cancel,  handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            
        case .restricted:
            print("restricted")
        default:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                [weak self]
                (granted :Bool) -> Void in
                if granted == true {
                    // User granted
                    print("User granted")
                    DispatchQueue.main.async(){
                        self?.startCamera()
                    }
                }else {
                    // User Rejected
                    print("User Rejected")
                    DispatchQueue.main.async(){
                        let alert = UIAlertController(title: "WHY?" , message:  "Camera it is the main feature of our application", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                        alert.addAction(action)
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            });
        }
    }
}

