//
//  ARSceneViewController.swift
//  ARKitCoreML
//
//  Created by Jason Clark on 10/11/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//
import ARKit
import SceneKit
import UIKit

final class ARSceneViewController: UIViewController {

    var diamondNode:SCNNode?
    let diamondScene = SCNScene(named: "diamond.scn")
    
    lazy var recognizer = MLRecognizer(
        model: LandCardClassifier().model,
        sceneView: sceneView
    )

    let detectionImages = ARReferenceImage.referenceImages(
        inGroupNamed: "AR Resources",
        bundle: nil
    )

    lazy var sceneView: ARSCNView = {
        let sceneView = ARSCNView()
        sceneView.delegate = self
        return sceneView
    }()

    lazy var refreshButton = UIBarButtonItem(
        barButtonSystemItem: .refresh,
        target: self, action: #selector(refreshButtonPressed)
    )

}

extension ARSceneViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        diamondNode = diamondScene?.rootNode

        title = "ARKit + CoreML"
        navigationItem.rightBarButtonItem = refreshButton

        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        view.subviews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        resetTracking()
    }

    func resetTracking() {
        let config = ARWorldTrackingConfiguration()
        config.detectionImages = detectionImages
        config.maximumNumberOfTrackedImages = 1
        config.isLightEstimationEnabled = true
        config.isAutoFocusEnabled = true
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

}

extension ARSceneViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }

        addIndicatorPlane(to: imageAnchor)

        // send off anchor to be screenshot and classified
        recognizer.classify(imageAnchor: imageAnchor) { [weak self] result in
            if case .success(let classification) = result {

                // update app with classification
                self?.attachLabel(classification, to: node)
            }
        }
        
        if let imageAnchor = anchor as? ARImageAnchor {
            let size = imageAnchor.referenceImage.physicalSize
            let plane = SCNPlane(width: size.width, height: size.height)
            plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
            plane.cornerRadius = 0.005
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi/2
            node.addChildNode(planeNode)
            
            
            var shapeNode:SCNNode?
            
            shapeNode = diamondNode
            
            guard let shape = shapeNode else {return}
            
            
            let shapeSpin = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
            let reapeatSpin = SCNAction.repeatForever(shapeSpin)
            shapeNode?.runAction(reapeatSpin)
            
            node.addChildNode(shape)
        }
    }

}

extension ARSceneViewController {

    /// Adds a plane atop `imageAnchor`
    func addIndicatorPlane(to imageAnchor: ARImageAnchor) {
        let node = sceneView.node(for: imageAnchor)
        let size = imageAnchor.referenceImage.physicalSize
        let geometry = SCNPlane(width: size.width, height: size.height)
        let plane = SCNNode(geometry: geometry)
        plane.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
        plane.geometry?.firstMaterial?.fillMode = .lines
        plane.eulerAngles.x = -.pi / 2
        
        /*var shapeNode:SCNNode?
        shapeNode = diamondNode
        guard let shape = shapeNode else {return}*/
        
        node?.addChildNode(plane)
        //node?.addChildNode(shape)
    }

    // Adds a label below `node`
    func attachLabel(_ title: String, to node: SCNNode) {
        let geometry = SCNText(string: title, extrusionDepth: 0)
        geometry.flatness = 0.1
        geometry.firstMaterial?.diffuse.contents = UIColor.darkText
        let text = SCNNode(geometry: geometry)
        text.scale = .init(0.00075, 0.00075, 0.00075)
        text.eulerAngles.x = -.pi / 2
        let box = text.boundingBox
        text.pivot.m41 = (box.max.x - box.min.x) / 2.0
        text.position.z = node.boundingBox.max.z + 0.012 // 1 cm below card
        node.addChildNode(text)
    }

}

extension ARSceneViewController {

    @objc func refreshButtonPressed() {
        resetTracking()
    }

}
