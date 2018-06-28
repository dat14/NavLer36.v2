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
import Vision
import Photos
import Foundation
import MessageUI
import AVKit

// Google pod APIs
import GoogleSignIn
import GoogleAPIClientForREST

// Global to pass path between views
var pathTitle :String = ""

// View object handling Google account login
class SignInViewcontroller: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    var window: UIWindow?
    
    private let scopes = [kGTLRAuthScopeDriveReadonly]
    private let service = GTLRDriveService()
    
    let signInButton = GIDSignInButton()
    
    // Debug field
    // @IBOutlet weak var inputPathTitle: UITextField!
    
    // Start video capture, and switch to camera view controller
    @IBAction func startRecording(_ sender: Any) {
        performSegue(withIdentifier: "segue1", sender: self)
    }
    
    // View init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
        
        // Add the sign-in button.
        view.addSubview(signInButton)
        signInButton.center = view.center
    }
    
    // Deallocate view
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // Process outcome of login attempt
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            showAlert(title: "Successful Login", message: "Press Start for Recording")
            self.signInButton.isHidden = true
            self.service.authorizer = user.authentication.fetcherAuthorizer()
        }
    }
    
    // Helper function: Constructs an alert box with arbitrary message
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    // Debug function: List up to 10 files in Drive
    func listFiles() {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 10
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:))
        )
    }
    
    // Debug function: Process the response and display output
    @objc func displayResultWithTicket(ticket: GTLRServiceTicket,
                                       finishedWithObject result : GTLRDrive_FileList,
                                       error : NSError?) {
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        var text = "";
        if let files = result.files, !files.isEmpty {
            text += "Files:\n"
            for file in files {
                text += "\(file.name!) (\(file.identifier!))\n"
            }
        } else {
            text += "No files found."
        }
    }
}
