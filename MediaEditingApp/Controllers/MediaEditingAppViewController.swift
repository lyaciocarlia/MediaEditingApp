//
//  MediaEditingAppViewController.swift
//  MediaEditingApp
//
//  Created by Iuliana Stecalovici  on 23.12.2022.
//

import UIKit
import PencilKit
import PhotosUI


class MediaEditingAppViewController: UIViewController,PKCanvasViewDelegate, PKToolPickerObserver, UIDropInteractionDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var drawingArea: PKCanvasView!
    
    
    let canvasWidth: CGFloat = 768
    let canvasOverscrollHeight: CGFloat = 500
    var drawing = PKDrawing()
    let toolPicker = PKToolPicker()
    
    @IBOutlet weak var workspace: WorkspaceView!
    
    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    var imageFetcher : ImageFetcher!
    
    @IBAction func saveImage(_ sender: UIBarButtonItem) {
        
        UIGraphicsBeginImageContextWithOptions(drawingArea.bounds.size, false, UIScreen.main.scale)
        
        drawingArea.drawHierarchy(in: drawingArea.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if image != nil{
            PHPhotoLibrary.shared().performChanges({PHAssetChangeRequest.creationRequestForAsset(from: image!)},
                                                   completionHandler: { succes, error in
                //hhjg
            })
        }
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
    }
   
    @IBAction func addImage(_ sender: UIBarButtonItem) {
        
        let vs = UIImagePickerController()
        vs.sourceType = .photoLibrary
        vs.delegate = self
        present(vs, animated: true)
    }
    }

// MARK: lifecycle

extension MediaEditingAppViewController{
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        toolPicker.addObserver(drawingArea)
        toolPicker.setVisible(true, forFirstResponder: drawingArea)
        drawingArea.becomeFirstResponder()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        drawingArea.delegate = self
        drawingArea.drawing = drawing
        
        drawingArea.alwaysBounceVertical = true
        drawingArea.drawingPolicy = .anyInput
        
    }
}

// MARK: image picker

extension MediaEditingAppViewController{
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.originalImage]
        workspace.backgroundImage = image as? UIImage
        picker.dismiss(animated: true)
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: drop delegate func

extension MediaEditingAppViewController{
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
           return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
       }
       
       func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
           return UIDropProposal(operation: .copy)
       }
      
      
       
       func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
           imageFetcher = ImageFetcher(){ (url, image) in
                          DispatchQueue.main.async {
                              self.workspace.backgroundImage = image
                          }
                      }
           
           session.loadObjects(ofClass: NSURL.self){ nsurls in
               if let url = nsurls.first as? URL{
                   self.imageFetcher.fetch(url)
               }
           }
           session.loadObjects(ofClass: UIImage.self){ images in
               if let image = images.first as? UIImage{
                   self.imageFetcher.backup = image
               }
           }

       }
}
