//  ViewController.swift
//  Lumeni
//  Created by Vibhhu Sharma on 27/03/21.

import UIKit
import AVKit
import Vision
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    func setupLandscapeView() -> UIViewController {
      let viewController = ViewController()
      viewController.modalPresentationStyle = .fullScreen
      return viewController
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let videoCaptureSession = AVCaptureSession()
        guard let camera =
                AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: camera) else { return }
        videoCaptureSession.addInput(input)
        videoCaptureSession.startRunning()
        
        let liveVideo = AVCaptureVideoPreviewLayer(session: videoCaptureSession)
        liveVideo.videoGravity = AVLayerVideoGravity.resizeAspectFill
        liveVideo.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        view.layer.addSublayer(liveVideo)
        liveVideo.frame = view.frame

        let videoOutput = AVCaptureVideoDataOutput()
        videoCaptureSession.addOutput(videoOutput)
        videoOutput.setSampleBufferDelegate(self, queue:
                                            DispatchQueue(label: "videoQueue"))
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = try? VNCoreMLModel(for: Resnet50(configuration: MLModelConfiguration()).model) else { return }
        
        let request = VNCoreMLRequest(model: model) {
            (finished, err) in
            guard let results = finished.results as? [ VNClassificationObservation] else { return }
            guard let objectName = results.first else { return }
            print(objectName.identifier, objectName.confidence)
            let spokenWord = AVSpeechUtterance(string: objectName.identifier)
            spokenWord.voice = AVSpeechSynthesisVoice(language: "en-GB")
            spokenWord.rate = 0.3
            let speechSynthesizer = AVSpeechSynthesizer()
            speechSynthesizer.speak(spokenWord)
            sleep(5)
        }
         try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
}

