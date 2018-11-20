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
        
        return sceneView
    }()
    
    lazy var sceneView: SCNView = {
        return SCNView(frame: self.view.frame)
    }()
    
    lazy var sunNode: SCNNode = {
       
        let geometry = SCNSphere(radius: 500)
        let result =  SCNNode(geometry: geometry)
        result.position = SCNVector3Make(0, 0, 0)
        return result
    }()
    
    lazy var earthNode: SCNNode = {
       
        let geometry = SCNSphere(radius: 5)
        return SCNNode(geometry: geometry)
    }()
    
    lazy var moonNode: SCNNode = {
        
        let geometry = SCNSphere(radius: 5)
        return SCNNode(geometry: geometry)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.addSubview(arSceneView)
        
//        view.addSubview(sceneView)
//        sceneView.autoenablesDefaultLighting = true
//
//        sceneView.scene = SCNScene()
//        sceneView.scene?.rootNode.addChildNode(sunNode)
        
        arSceneView.debugOptions = [.showWorldOrigin]

        arSceneView.scene = SCNScene()

        arSceneView.scene.rootNode.addChildNode(sunNode)
        
        let configuration = ARWorldTrackingConfiguration()
        arSceneView.session.run(configuration)
    }
}

