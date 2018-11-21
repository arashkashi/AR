//
//  ViewController.swift
//  AR
//
//  Created by Arash Kashi on 2018-11-20.
//  Copyright © 2018 Arash Kashi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    lazy var arSceneView: ARSCNView = {
        
        let sceneView = ARSCNView(frame: view.frame)
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        sceneView.allowsCameraControl = true
        
        sceneView.delegate = self
        
        return sceneView
    }()
    
    lazy var sceneView: SCNView = {
        return SCNView(frame: self.view.frame)
    }()
    
    lazy var sunNode: SCNNode = {
       
        let geometry = SCNSphere(radius: 0.07)
        let result =  SCNNode(geometry: geometry)
        result.position = SCNVector3Make(0.0, 0.0, 0.0)
        return result
    }()
    
    lazy var earthNode: SCNNode = {
       
        let geometry = SCNSphere(radius: 0.03)
        let result =  SCNNode(geometry: geometry)
        result.position = SCNVector3Make(0.0, 0.0, 0.5)
        return result
    }()
    
    lazy var moonNode: SCNNode = {
        
        let geometry = SCNSphere(radius: 0.02)
        return SCNNode(geometry: geometry)
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = processPipeline
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.addSubview(arSceneView)
        
        arSceneView.debugOptions = [.showWorldOrigin]

        arSceneView.scene = SCNScene()
        arSceneView.scene.rootNode.addChildNode(sunNode)
        arSceneView.scene.rootNode.addChildNode(earthNode)
        arSceneView.scene.rootNode.addChildNode(moonNode)
        
        let configuration = ARWorldTrackingConfiguration()
        arSceneView.session.run(configuration)
        
        let button = UIButton(frame: CGRect(x: 10, y: 10, width: 44, height: 44))
        button.backgroundColor = .white
        self.view.addSubview(button)
        button.addTarget(self, action: #selector(onButtonTapped), for: .touchUpInside)
    }
    
    var isImageCaptureEnabled: Bool = false
    
    @objc func onButtonTapped() {
        
        isImageCaptureEnabled = !isImageCaptureEnabled
    }
    
    private var currentTime: TimeInterval?
    
    private let sunEarchDistance: Float = 0.5
    private let earchMoonDistance: Float = 0.1
    
    private let earchSpeed: Double = 20.0
    private let moonSpeed: Double = 500.0
    
    let first = PixelBufferToDataProcessBlock(name: "Pixelbuffer to Data")
    
    lazy var processPipeline: PipelineProcessNode<CVPixelBuffer, Data, Int> = {
        
        
        let second = JpegDataToDiskProcessBlock(name: "Jpeg data to disk")
        return PipelineProcessNode(head: first, next: second)
    }()
}


import MetalKit


extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        let earthX = Float(sin(Double.pi / 180 * time * earchSpeed)) * sunEarchDistance
        let earchZ = Float(cos(Double.pi / 180 * time * earchSpeed)) * sunEarchDistance
        
        let moonX = earthX + Float(sin(Double.pi / 180 * time * moonSpeed)) * earchMoonDistance
        let moonZ = earchZ + Float(cos(Double.pi / 180 * time * moonSpeed)) * earchMoonDistance
        
        earthNode.position = SCNVector3Make(earthX, 0.0, earchZ)
        moonNode.position = SCNVector3Make(moonX, 0.0, moonZ)
        
        if isImageCaptureEnabled == false { return }
        
        if let frame = arSceneView.session.currentFrame?.capturedImage {
            
            first.enqueueInput(item: frame)
        }
    }
    
}


class ImageViewController: UIViewController {
    
    init(image: UIImage) {
        
        super.init(nibName: nil, bundle: nil)
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)
        imageView.frame = self.view.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}






