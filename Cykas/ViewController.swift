//
//  ViewController.swift
//  Cykas
//
//  Created by Maurizio Casciano on 29/03/2017.
//  Copyright © 2017 Maurizio Casciano. All rights reserved.
//

import UIKit
import AVFoundation
import PennyPincher
import LocalAuthentication
import CryptoSwift
import CoreData

class ViewController: UIViewController, UITextFieldDelegate,AVCaptureMetadataOutputObjectsDelegate{
    
    private let pennyPincherGestureRecognizer = PennyPincherGestureRecognizer()
   // @IBOutlet var titleLabel: UILabel!
    //@IBOutlet var messageLabel: UILabel!
    //@IBOutlet var gestureLabel: UILabel!
   
   // @IBOutlet var clearButton: UIButton!
    @IBOutlet weak var labelQR: UILabel!
    @IBOutlet weak var imgQR: UIImageView!
    @IBOutlet var gestureView: GestureView!
    
    var template:PennyPincherTemplate!
    
    var QRCODEONLY = true
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    @IBOutlet weak var StackView: UIStackView!
    var gesture = [TemplateGesture]()
    override func viewDidLoad() {
        super.viewDidLoad()
        gesture = PersistenceManager.fetchData()
       /* for p in gesture{
            PersistenceManager.deleteItem(item: p)
        }*/
        var y = [CGPoint]()
        for pointgesture in gesture{
            y.append(CGPointFromString(pointgesture.point!))
        }
        template = PennyPincher.createTemplate("pass", points: y)!
        pennyPincherGestureRecognizer.templates.append(template)
                // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.

		pennyPincherGestureRecognizer.enableMultipleStrokes = true
		pennyPincherGestureRecognizer.allowedTimeBetweenMultipleStrokes = 0.2
		pennyPincherGestureRecognizer.cancelsTouchesInView = false
		pennyPincherGestureRecognizer.addTarget(self, action: #selector(didRecognize(_:)))
		
		gestureView.addGestureRecognizer(pennyPincherGestureRecognizer)
		
		if(QRCODEONLY){
			let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
			
			do {
				// Get an instance of the AVCaptureDeviceInput class using the previous device object.
				let input = try AVCaptureDeviceInput(device: captureDevice)
				
				// Initialize the captureSession object.
				captureSession = AVCaptureSession()
				
				// Set the input device on the capture session.
				captureSession?.addInput(input)
				
			} catch {
				// If any error occurs, simply print it out and don't continue any more.
				print(error)
				return
			}
			
			
			// Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
			let captureMetadataOutput = AVCaptureMetadataOutput()
			captureSession?.addOutput(captureMetadataOutput)
			
			// Set delegate and use the default dispatch queue to execute the call back
			captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
			
			// Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
			videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
			videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
			videoPreviewLayer?.frame = view.layer.bounds
			view.layer.addSublayer(videoPreviewLayer!)
			
			// Start video capture.
			captureSession?.startRunning()
			
			
			// Move the message label and top bar to the front
			//view.bringSubview(toFront: messageLabel)
			//view.bringSubview(toFront: titleLabel)
			//view.bringSubview(toFront: gestureLabel)
			//view.bringSubview(toFront: clearButton)
            view.bringSubview(toFront: labelQR)
            view.bringSubview(toFront: imgQR)
			view.bringSubview(toFront: gestureView)
            view.bringSubview(toFront: StackView)
			
			// Initialize QR Code Frame to highlight the QR code
			qrCodeFrameView = UIView()
			
			if let qrCodeFrameView = qrCodeFrameView {
				qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
				qrCodeFrameView.layer.borderWidth = 2
				view.addSubview(qrCodeFrameView)
				view.bringSubview(toFront: qrCodeFrameView)
			}
		}
		
	}


    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            //messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                let addActionSheet = UIAlertController.init(
                    title: "Go To:",
                    message: metadataObj.stringValue,
                    preferredStyle: UIAlertControllerStyle.init(rawValue: 1)!)
                
                
                addActionSheet.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
                
                
                addActionSheet.addAction(UIAlertAction.init(title: "Yes ",style: .default,
                                                            handler: {(action: UIAlertAction) in
                                                                UIApplication.shared.open(URL(string: "https://www.google.com/search?q="+metadataObj.stringValue)!, options: [:], completionHandler: nil)
                                                                
                }))
                
                self.present(addActionSheet, animated: true, completion: nil)
                
            }
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func didRecognize(_ pennyPincherGestureRecognizer: PennyPincherGestureRecognizer) {
        switch pennyPincherGestureRecognizer.state {
        case .ended, .cancelled, .failed:
            print("Riconosciuto")
            updateRecognizerResult()
        default: break
        }
    }
    
    private func updateRecognizerResult() {
        print("update recognizer")
        guard let (template, similarity) = pennyPincherGestureRecognizer.result else {
          //  gestureLabel.text = "Could not recognize."
            return
        }
        
        let similarityString = String(format: "%.2f", similarity)
        //gestureLabel.text = "Template: \(template.id), Similarity: \(similarityString)"
        if(Double(similarityString)!>8.0){
            AuthenticateWithTouchID()
        }
    }
    
    
    @IBAction func didTapClear(_ sender: Any) {
      //  gestureLabel.text = "Inserire la nuova gesture e premere add"
        for point in gesture{
            PersistenceManager.deleteItem(item: point)
        }
        PersistenceManager.saveContext()
        gesture = PersistenceManager.fetchData()
        pennyPincherGestureRecognizer.templates.removeAll()
        gestureView.clear()
    }
    
    let msg1 = NSLocalizedString("Access requires authentication", comment: "Richiesto accesso")
    let msg2 = NSLocalizedString("Session cancelled", comment: "Sessione cancellata")
    let msg3 = NSLocalizedString("Please try again", comment: "Riprova")
    let msg4 = NSLocalizedString("Authentication", comment: "Autenticazione")
    let msg5 = NSLocalizedString("Password option selected", comment: "Password option selected")
    let msg6 = NSLocalizedString("Authentication failed", comment: "Autentucazione fallita")
    
    let msg7 = NSLocalizedString("TouchID is not enrolled", comment: "TouchID non settato")
    let msg8 = NSLocalizedString("If you want use this app, you need to set a touch id ", comment: "TouchID non settato")
    
    let msg9 = NSLocalizedString("A passcode has not been set", comment: "A passcode has not been set")
    let msg10 = NSLocalizedString("TouchID not available", comment: "TouchID not available")

    
    
    

    
    

    

    
    func AuthenticateWithTouchID() {
        let context = LAContext()
        
        var error: NSError?
        
        if context.canEvaluatePolicy(
            LAPolicy.deviceOwnerAuthenticationWithBiometrics,
            error: &error) {
            
            // Device can use TouchID
            context.evaluatePolicy(
                LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                localizedReason: msg1,
                reply: {(success, error) in
                    DispatchQueue.main.async {
                        
                        if error != nil {
                            
                            switch error!._code {
                                
                            case LAError.Code.systemCancel.rawValue:
                                self.notifyUser(self.msg2,
                                                err: error?.localizedDescription)
                                
                            case LAError.Code.userCancel.rawValue:
                                self.notifyUser(self.msg3,
                                                err: error?.localizedDescription)
                                
                            case LAError.Code.userFallback.rawValue:
                                self.notifyUser(self.msg4,
                                                err: self.msg5)
                                // Custom code to obtain password here
                                
                            default:
                                self.notifyUser(self.msg6,
                                                err: error?.localizedDescription)
                            }
                            
                        } else {
                            // self.notifyUser("Authentication Successful",err: "You now have full access")
                            self.performSegue(withIdentifier: "secretSegue", sender: nil)
                            
                        }
                    }
            })
        } else {
            // Device cannot use TouchID
            switch error!.code{
                
            case LAError.Code.touchIDNotEnrolled.rawValue:
                notifyUser(msg7,
                           err: msg8)
                
                
            case LAError.Code.passcodeNotSet.rawValue:
                notifyUser(msg9,
                           err: msg8)
     
                
                
            default:
                notifyUser(msg10,
                           err: msg8)
                
            }
        }
    }
    
    func notifyUser(_ msg: String, err: String?) {
        let alert = UIAlertController(title: msg,
                                      message: err,
                                      preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "OK",
                                         style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true,
                     completion: nil)
    }
    
}

