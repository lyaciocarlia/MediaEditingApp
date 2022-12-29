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
        
        let drawing = self.drawingArea.drawing.image(from: self.drawingArea.bounds, scale: 0)
        if let markedupImage = self.saveImage(drawing: drawing){
            PHPhotoLibrary.shared().performChanges({PHAssetChangeRequest.creationRequestForAsset(from: markedupImage)}, completionHandler: { succes, error in
                // --
            })
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func saveImage(drawing : UIImage) -> UIImage? {
        let bottomImage = self.workspace.backgroundImage!
        let newImage = autoreleasepool { () -> UIImage in
            UIGraphicsBeginImageContextWithOptions(self.drawingArea!.frame.size, false, 0.0)
            bottomImage.draw(in: CGRect(origin: CGPoint.zero, size: self.drawingArea!.frame.size))
            drawing.draw(in: CGRect(origin: CGPoint.zero, size: self.drawingArea!.frame.size))
            let createdImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return createdImage!
        }
        return newImage
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
                self.drawingArea.isOpaque = true
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
