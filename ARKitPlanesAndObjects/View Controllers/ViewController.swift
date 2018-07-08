//
//  ViewController.swift
//  ARKitPlanesAndObjects
//
//  Created by Ignacio Nieto Carvajal on 04/09/2017.
//  Copyright © 2017 Digital Leaves. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

let maxObjects = 5

class ViewController: UIViewController, ARSCNViewDelegate {
    // outlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    // Added label to show how many objects have been removed
    @IBOutlet weak var countLabel: UILabel!
    // Added label to show the game has ended
    @IBOutlet weak var winLabel: UILabel!
    
    // Strings to names and files that are used in the project
    let daeFileName = "mug.dae"
    let daeObject = "Mug"
    let planeName = "Plane"
    let sphereName = "Sphere"
    
    // Other useful references to keep track
    var numberOfObjects: Set<SCNNode>?
    var sphereObject: SCNNode?
    
    // Reference to the object node
    var mugNode: SCNNode!
    
    // Planes: every plane is identified by a UUID.
    var planes = [UUID: VirtualPlane]() {
        didSet {
            if planes.count > 0 {
                currentCaffeineStatus = .ready
            } else {
                if currentCaffeineStatus == .ready { currentCaffeineStatus = .initialized }
            }
        }
    }
    
    var currentCaffeineStatus = ARCoffeeSessionState.initialized {
        didSet {
            DispatchQueue.main.async { self.statusLabel.text = self.currentCaffeineStatus.description }
            if currentCaffeineStatus == .failed {
                cleanupARSession()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // configure settings and debug options for scene
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, SCNDebugOptions.showConstraints, SCNDebugOptions.showLightExtents, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.automaticallyUpdatesLighting = true

        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // round corners of status label
        statusLabel.layer.cornerRadius = 20.0
        statusLabel.layer.masksToBounds = true
        
        // initialize coffee node
        self.initializeMugNode()
        
        // This helps to keep the counter for objects in the plane
        numberOfObjects = Set()
        // Label with the number of objects in a plane
        countLabel.text = "☕️#0"
        // Hide the win label until the end
        winLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        if planes.count > 0 { self.currentCaffeineStatus = .ready }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        self.currentCaffeineStatus = .temporarilyUnavailable
    }
    
    func initializeMugNode() {
        // Obtain the scene the coffee mug is contained inside, and extract it.
        let mugScene = SCNScene(named: daeFileName)!
        self.mugNode = mugScene.rootNode.childNode(withName: daeObject, recursively: true)!
    }
    
    // MARK: - Adding, updating and removing planes in the scene in response to ARKit plane detection.
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // create a 3d plane from the anchor
        if let arPlaneAnchor = anchor as? ARPlaneAnchor {
            let plane = VirtualPlane(anchor: arPlaneAnchor)
            // Helps to name it to later recognize it
            plane.name = planeName
            self.planes[arPlaneAnchor.identifier] = plane
            node.addChildNode(plane)
            print("Plane added: \(plane)")
            // At time of creation, other objects are attached as well
            addObjectsToPlane(plane)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let plane = planes[arPlaneAnchor.identifier] {
            // This helps a plane to increase its accurracy
            plane.updateWithNewAnchor(arPlaneAnchor)
            print("Plane updated: \(plane)")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let index = planes.index(forKey: arPlaneAnchor.identifier) {
            print("Plane updated: \(planes[index])")
            planes.remove(at: index)
        }
    }
    
    // MARK: - Cleaning up the session
    
    func cleanupARSession() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
    }
    
    // MARK: - Session tracking methods
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        self.currentCaffeineStatus = .failed
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        self.currentCaffeineStatus = .temporarilyUnavailable
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        self.currentCaffeineStatus = .ready
    }
    
    // MARK: - Selecting planes and adding out coffee mug.
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            print("Unable to identify touches on any plane. Ignoring interaction...")
            return
        }
        
        if currentCaffeineStatus != .ready {
            print("Unable to place objects when the planes are not ready...")
            return
        }
        
        let touchPoint = touch.location(in: sceneView)
        print("Touch happened at point: \(touchPoint)")
        
        if let hit = sceneView.hitTest(touch.location(in: sceneView), options: nil).first {
            let node = hit.node
            
            // Has the collision happened against an object??
            if daeObject == node.name {
                // Remove that object from the scene and the set
                node.removeFromParentNode()
                numberOfObjects?.remove(node)
                // Update the label with number of objects
                countLabel.text = "☕️#\(numberOfObjects?.count ?? 0)"
            }
            
            if numberOfObjects?.count == 0 {
                // Small easter egg
                statusLabel.text = "Finish it"
            }
            
            if sphereName == node.name {
                if numberOfObjects?.count != 0 { return }
                // Once all objects have been eliminated, it is time
                // for the sphere to disappear
                node.removeFromParentNode()
                // Show who's the winner
                winLabel.isHidden = false
            }
        }
    }
    
    func addObjectsToPlane(_ plane: VirtualPlane, amount: Int = maxObjects) {
        let sphereNode = createSphereNode(createSphere(0.05, getSphereMaterial(UIColor.blue)))
        sphereObject = sphereNode
        plane.addChildNode(sphereNode)

        for i in 0...amount {
            let objClone = cloneObjectNode(Float(i))
            plane.addChildNode(objClone)
            numberOfObjects?.insert(objClone)
        }
    }

    // Pure function that creates materials with passed color
    func getSphereMaterial(_ color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        return material
    }
    
    // Pure function that create an sphere
    func createSphere(_ radius: CGFloat, _ material: SCNMaterial) -> SCNSphere {
        let sphere = SCNSphere(radius: radius)
        sphere.materials = [material]
        return sphere
    }
    
    // Function that creates an sphere node
    func createSphereNode(_ sphere: SCNSphere) -> SCNNode {
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = sphereName
        sphereNode.position = SCNVector3Zero
        return sphereNode
    }
    
    // Function that clones mugNode
    func cloneObjectNode(_ position: Float) -> SCNNode {
        let objClone = mugNode.clone()
        objClone.position = SCNVector3Make(cos(position) * 0.1, 0.01, sin(position) * 0.1)
        objClone.name = daeObject
        return objClone
    }
}
