//
//  ViewController.swift
//  PosTrekDrive
//
//  Created by Duy An Tran on 30/04/2018.
//  Copyright © 2018 Duy An Tran. All rights reserved.
//

// Apple swift framework
import UIKit
import ARKit
import SceneKit

// Global variables to hold captured data, and transfer to Save View Controller
var Timestamp: String {
    return "\(NSDate().timeIntervalSince1970 * 1000000)" // Converts timestamp to integer type
}
var csvText = ""
var fullPathsText = ""
var counter = 0


// The View Controller manipulates the frame buffer to allow extraction of image data
// Visual odometry (with Kalman filter) for creating a low noise datastream of device position and orientation,
// complementing the raw accelerometer data

class SceneViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UITextViewDelegate{
    
    @IBOutlet var sceneView: ARSCNView!
    
    // Exits data capturing session
    @IBAction func stopRecording(_ sender: Any) {
        performSegue(withIdentifier: "segue2", sender: self)
    }
    
    // Label object to display Position vector
    let identifierLabel1: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Label object to display Orientation vector
    let identifierLabel2: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Positioning label object
    fileprivate func setupIdentifierConfidenceLabel1() {
        view.addSubview(identifierLabel1)
        identifierLabel1.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel1.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel1.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel1.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    // Positioning label object
    fileprivate func setupIdentifierConfidenceLabel2() {
        view.addSubview(identifierLabel2)
        identifierLabel2.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 18).isActive = true
        identifierLabel2.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel2.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel2.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    override func viewDidLoad() {
        setupScene()
        setupIdentifierConfidenceLabel1()
        setupIdentifierConfidenceLabel2()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // DEBUG NOTIFICATIONS
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    // Set up the sceneView.
    func setupScene() {
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        
        sceneView.preferredFramesPerSecond = 30
        
        sceneView.contentScaleFactor = 2     // High DPI scaling
        sceneView.showsStatistics = true     // Debug: Display program resource usage (Memory, CPU etc.)
        sceneView.allowsCameraControl = true // Allow user interaction with Camera Module
        
        // Assigning objects to scene + Rendering Scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Initialize odometry feature points
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        // TBD -- apply these settings to the camera
        /*
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        */
 
    }

    // Function called whenever view is updated. Extracts Image, Position and Orientation data
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // Manipulation of frame buffer to export image data
        DispatchQueue.global(qos: .userInitiated).async {
            let imageBuffer: CVPixelBuffer = (frame.capturedImage) // Catch current image buffer
            
            // Type conversion
            let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
            let image : UIImage = convert(image: ciimage)
            
            // Save image with name of current Timestamp
            saveImage(image: image, withName: "\(Timestamp)")
            
            let currentFootage = pathTitle
            let fileName = "Path_No_\(String(describing: currentFootage)).csv"
            
            let transform = frame.camera.transform
            let angles = frame.camera.eulerAngles
            
            var location = [-transform[3][0], -transform[3][1], -transform[3][2]]
            var eulerOrientation = [angles[0], angles[1], angles[2]]
            
            let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            let newLine = "\(Timestamp), \(location[0]), \(location[1]), \(location[2]),\(eulerOrientation[0]), \(eulerOrientation[1]), \(eulerOrientation[2])\n"
            csvText.append(newLine)
            try? csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            counter += 1
            
            // Debug modes
            // print("CSV saved to \(String(describing: path))")
            // print("Location: \(location)")
            // print("Orientation: \(eulerOrientation)")
        }
        
        // Position and Orientation vector extraction
        DispatchQueue.main.async (execute: {
            let transform = frame.camera.transform
            let angles = frame.camera.eulerAngles
            
            let location = [-transform[3][0], -transform[3][1], -transform[3][2]]
            let eulerOrientation = [angles[0], angles[1], angles[2]]
            
            // Add a UITextView to display output.
            self.identifierLabel1.text = "Location: \(location)"
            self.identifierLabel2.text = "Orientation: \(eulerOrientation)"
            // Debug: print("Success")
        })
    }
}

