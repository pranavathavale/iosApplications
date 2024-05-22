//
//  ViewController.swift
//  WhatFlower
//
//  Created by Pranav Athavale on 27/04/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var infoLabel: UILabel!
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
          //  imageView.image = userPickedImage
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Failed to convert image into ciimage")
            }
            detect(image: ciimage)
          
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model)  else {
            fatalError("Cannot get the coreML model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results?.first as? VNClassificationObservation else {
                fatalError("Cannot complete request")
            }
            
            self.navigationItem.title = results.identifier.capitalized
            self.requestInfo(flowerName: results.identifier)
        }
        
    
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName,
          "indexpageids" : "",
          "redirects" : "1",
            "pithumbsize": "500"
          ]
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
            case .success:
                    print("Got info from wikipedia")
                    print(JSON(response.value))
                    let flowerJSON: JSON = JSON(response.value!)
                    let pageid = flowerJSON["query"]["pageids"][0].stringValue
                    let flowerDesciption = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                    let flowerWebImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                    self.imageView.sd_setImage(with: URL(string: flowerWebImageURL))
                    self.infoLabel.text = flowerDesciption
                
              
            case .failure:
                print("Failed to get info from wikipedia")
            }
            
        }
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

