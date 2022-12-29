//
//  WorkspaceView.swift
//  MediaEditingApp
//
//  Created by Iuliana Stecalovici  on 23.12.2022.
//

import UIKit

class WorkspaceView: UIView {

    var backgroundImage: UIImage?{
        didSet{
            setNeedsDisplay()
        }
    }
    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: bounds)
    }
    

}
