//
//  SaveDataViewController.swift
//  PosTrekDrive
//
//  Created by Duy An Tran on 01/05/2018.
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
import Zip


// View provides user interface for saving data in .csv, captured images in .png formats, OR compressed zip files
// Data can be collected through Google Drive or Email
// Memory/cache can be cleared.
// TBD: The user can initiate a new capture session

class SaveDataViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, GIDSignInUIDelegate{

    // View init
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    // Deallocation
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // User input field -- Email
    @IBOutlet weak var emailText: UITextField!
    
    // User input button -- Send data to email
    @IBAction func sendEmail(_ sender: Any) {
        let currentFootage = pathTitle
        
        // NOTE!!! Apple email library takes NSURL not String path
        let fileName = "Path_No_\(String(describing: currentFootage)).csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        // Create helper object for sending Email
        if MFMailComposeViewController.canSendMail() {
            // Compose email contents
            let emailController = MFMailComposeViewController()
            emailController.mailComposeDelegate = self
            emailController.setToRecipients([emailText.text!])
            emailController.setSubject("\(String(describing: currentFootage)) data export")
            emailController.setMessageBody("Hi,\n\nThe .csv data export is attached\n\n\nSent from the PosTrek app.", isHTML: false)
            // Attach .csv file containing Ground Truth data
            do {emailController.addAttachmentData(try NSData(contentsOf: path!) as Data, mimeType: "text/csv", fileName: "\(String(describing: currentFootage)).csv")} catch {
                print("STD")
            }
            
            // Displays message
            present(emailController, animated: true, completion: nil)
        }
        
        // Closes email dialog
        func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
    
    
    
    // TBD -- composes email with .zip attachment
    /*
    @IBAction func sendEmailZip(_ sender: Any) {
        let currentFootage = pathTitle
        
        let fileName = "archive.zip"
        let paths = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true))
        let docs = paths as NSString
        let fullPath = docs.appendingPathComponent(fileName)
        if MFMailComposeViewController.canSendMail() {
            let emailController = MFMailComposeViewController()
            emailController.mailComposeDelegate = self
            emailController.setToRecipients([emailText.text!])
            emailController.setSubject("\(String(describing: currentFootage)) data export")
            emailController.setMessageBody("Hi,\n\nThe .zip data export is attached\n\n\nSent from the PosTrek app.", isHTML: false)
            
            do {emailController.addAttachmentData(try NSData(contentsOf: paths) as Data, mimeType: "zip", fileName: "archive.zip")} catch {
                print("STD")
            }
            
            present(emailController, animated: true, completion: nil)
        }
        func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
            controller.dismiss(animated: true, completion: nil)
            controller.isToolbarHidden = true
        }
     }
     */
    
    // Uploads a photo array to Google Drive
    /*
    func uploadPhoto(image: UIImage) {
        println("uploading Photo")
        let dateFormat  = NSDateFormatter()
        dateFormat.dateFormat = "'Quickstart Uploaded File ('EEEE MMMM d, YYYY h:mm a, zzz')"
        
        let file = GTLDriveFile.object() as GTLDriveFile
        file.title = dateFormat.stringFromDate(NSDate())
        file.descriptionProperty = "Uploaded from Google Drive IOS"
        file.mimeType = "image/png"
        
        let data = UIImagePNGRepresentation(image)
        let uploadParameters = GTLUploadParameters(data: data, MIMEType: file.mimeType)
        let query = GTLQueryDrive.queryForFilesInsertWithObject(file, uploadParameters: uploadParameters) as GTLQueryDrive
        let waitIndicator = self.showWaitIndicator("Uploading To Google Drive")
        
        self.driveService.executeQuery(query, completionHandler:  { (ticket, insertedFile , error) -> Void in
            let myFile = insertedFile as? GTLDriveFile
            
            waitIndicator.dismissWithClickedButtonIndex(0, animated: true)
            if error == nil {
                println("File ID \(myFile?.identifier)")
                self.showAlert("Google Drive", message: "File Saved")
            } else {
                println("An Error Occurred! \(error)")
                self.showAlert("Google Drive", message: "Sorry, an error occurred!")
            }
            
        }
     }
     */
 
    // TBD -- DEBUG THIS
    // Saves .zip attachments to user's Google Drive account
    @IBAction func saveToDrive(_ sender: Any) {

        // Assert that attachment exists
        guard let filePath = Bundle.main.path(forResource: "archive", ofType: "zip") else {
            // Debug: print("No such file in bundle")
            showSaveAlert(title: "ERROR", message: "No such file in bundle")
            return
        }
        // Assert that attachment is readable
        guard let fileData = FileManager.default.contents(atPath: filePath) else {
            // Debug: print("Can't read file")
            showSaveAlert(title: "ERROR", message: "Can't read file")
            return
        }
        
        // TBD -- Select Google Drive folder for saving data
        //let folderId: String = self.fileId!
        let metadata = GTLRDrive_File.init()
        metadata.name = "archive"
        metadata.mimeType = "application/zip"
        //metadata.parents = [appDataFolder]
        
        // Perform Upload
        let uploadParameters = GTLRUploadParameters(data: fileData , mimeType: "zip")
        uploadParameters.shouldUploadWithSingleRequest = true
        let query = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: uploadParameters)
        query.fields = "id"
    }
    

    
    // Creates .zip file
    @IBAction func zippingImages(_ sender: Any) {
        do {
            let filePath = NSURL(fileURLWithPath:  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            let zipFilePath = try Zip.quickZipFiles([filePath as URL], fileName: "archive") // Zip
            showAlert(title: "Successful Zipping", message: "Press OK to continue")
        }
        catch {
            print("An error has occured.")
        }
    }

    // Deallocate cached files from the Documents directory
    func clearDiskCache() {
        let fileManager = FileManager.default
        let myDocuments = NSURL(fileURLWithPath:  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        //let diskCacheStorageBaseUrl = myDocuments.appendingPathComponent("diskCache")
        guard let filePaths = try? fileManager.contentsOfDirectory(at: myDocuments as URL, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            try? fileManager.removeItem(at: filePath)
        }
    }
    
    // User Input Button -- Delete Cached files
    @IBAction func deletingImages(_ sender: Any) {
        clearDiskCache()
    }
    
    // DEBUGGING
    // Upload a single image
    func uploadPhoto(image: UIImage) {
        // Debug: print("uploading Photo")
        
        let file  = GTLRDrive_File() as GTLRDrive_File
        file.name = "\(Timestamp)"
        file.descriptionProperty = "Uploaded from Google Drive IOS"
        file.mimeType = "image/png"
        
        let data = UIImagePNGRepresentation(image)
        let uploadParameters = GTLRUploadParameters(data: data!, mimeType: file.mimeType!)
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
        // FIX THIS
        // let waitIndicator = self.showWaitIndicator(title: "Uploading To Google Drive")
    }
    
    // Helper function: Constructs an alert box with arbitrary message
    func showSaveAlert(title : String, message: String) {
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
    
}
