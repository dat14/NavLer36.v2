//
//  Utilities.swift
//  PosTrekDrive
//
//  Created by Duy An Tran on 01/05/2018.
//  Copyright © 2018 Duy An Tran. All rights reserved.
//

// Apple swift framework
import Foundation
import ARKit
import UIKit

// Convert CIImage to UIImage.
func convert(image:CIImage) -> UIImage {
    let image:UIImage = UIImage.init(ciImage: image)
    return image
}

/*
// Convert CIImage to UIImage. Alternative implementation
func convert(cmage:CIImage) -> UIImage{
    let context:CIContext = CIContext.init(options: nil)
    let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
    let image:UIImage = UIImage.init(cgImage: cgImage)
    return image
}
*/

// Array of undefined size to hold image data
var imageArray : NSMutableArray = NSMutableArray()

// Struct holds image object and the aassociated timestamp
struct imageX {
    var image: UIImage
    var name: String
}

// Saving a single UIImage with name according to current Timestamp.
func saveImage(image: UIImage, withName name: String) {
    let image = resizeImage(image : image)
    let imageData = NSData(data: UIImagePNGRepresentation(image)!)
    let petItem = imageX(image : image, name : name)
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let docs = paths as NSString
    let fullPath = docs.appendingPathComponent("\(name).png")
    _ = imageData.write(toFile: fullPath, atomically: true)

    // Debug use
    // print("UIImage saved to \(fullPath)")
}

// Resize image object
func resizeImage(image: UIImage) -> UIImage {
    let size = image.size
    
    var ratio :CGFloat
    ratio = 3
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    
    newSize = CGSize(width: size.width / ratio, height: size.height / ratio)
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}
