//
//  ViewController.swift
//  RKTest
//
//  Created by bunnyhero on 2021-05-01.
//

import os
import UIKit
import RealityKit
import ARKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var coachingOverlay: ARCoachingOverlayView!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var pickerConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: UILabel!
    
    var gunEntity: Entity!
    var spaceManager: SpaceManager!
    var selectedLocation: Location?
    var populatedLocations: [Location] = []
    
    var pickerViewController: LocationPickerViewController!
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "View")
    
    private var loadListener: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth, .personSegmentationWithDepth]) {
            config.frameSemantics = [.sceneDepth, .personSegmentationWithDepth]
        }
        
        arView.session.run(config)
        
        coachingOverlay.session = arView.session
        coachingOverlay.activatesAutomatically = true
//        arView.debugOptions = [.showAnchorGeometry, .showSceneUnderstanding]
        
        arView.environment.sceneUnderstanding.options.insert(.occlusion)

        // Load gun and attach to camera
        if let entity = try? Entity.loadModel(named: "Portal_gun_Rick_and_Morty") {
            let cameraAnchor = AnchorEntity(.camera)
            entity.setParent(cameraAnchor)
            let rotation = Transform(pitch: 0, yaw: -.pi / 2, roll: 0)
            let scaleFactor = Float(1.0/20.0)
            entity.transform = Transform(
                scale: entity.transform.scale * scaleFactor,
                rotation: rotation.rotation,
                translation: [Float(0.7 * scaleFactor), Float( -2.5 * scaleFactor), Float(-7 * scaleFactor)]
            )
            arView.scene.addAnchor(cameraAnchor)
            gunEntity = entity
        }
        
        spaceManager = SpaceManager(arView: arView)
        
        // Disable interactions with the gun until the multiverse data has been downloaded
        if DataManager.shared.multiverse == nil {
            fireButton.isHidden = true
            loadListener = NotificationCenter.default.addObserver(
                forName: AppDelegate.multiverseDidLoadNotification, object: nil, queue: .main
            ) { _ in
                self.fireButton.isHidden = false
                self.loadListener = nil
                self.chooseInitialLocation()
            }
        } else {
            chooseInitialLocation()
        }
        
        // Make labels look less harsh
        locationLabel.layer.cornerRadius = 10
        locationLabel.layer.masksToBounds = true
        messageLabel.layer.cornerRadius = 10
        messageLabel.layer.masksToBounds = true
    }
    
    private func chooseInitialLocation() {
        populatedLocations = DataManager.shared.multiverse.locations
            .filter({ $0.residents.count != 0})
            .sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        selectedLocation = populatedLocations.randomElement()
        locationLabel.text = selectedLocation?.name
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? LocationPickerViewController {
            pickerViewController = viewController
            pickerViewController.delegate = self
        }
    }
    
    @IBAction func didTapFireButton(_ sender: Any) {
        guard DataManager.shared.multiverse != nil else {
            logger.info("Multiverse not loaded yet")
            return
        }
        guard let location = selectedLocation else { return }
        if spaceManager.shootPortal(into: location) {
            // Randomly choose another location for the next shot
            selectedLocation = populatedLocations.randomElement()
            locationLabel.text = selectedLocation?.name
        } else {
            flashMessage("Could not find suitable surface for portal")
        }
    }
    
    
    @IBAction func didTapDimensionLabel(_ sender: Any) {
        guard DataManager.shared.multiverse != nil else {
            logger.info("Multiverse not loaded yet")
            return
        }
        pickerViewController.locations = populatedLocations
        pickerViewController.currentLocation = selectedLocation
        UIView.animate(withDuration: 0.25) {
            self.pickerConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func didTapArView(_ sender: UITapGestureRecognizer) {
        guard let entity = arView.entity(at: sender.location(in: arView)) else {
            logger.debug("*** no entity at tap")
            return
        }
        guard
            let personaCardComponent = entity.components[PersonaCardComponent.self] as? PersonaCardComponent,
            let personaCard = personaCardComponent.personaCard
        else {
            logger.debug("*** no persona in entity")
            return
        }
        flashMessage("That's \(personaCard.persona.name)")
        personaCard.stopSpin()
    }
    
    func flashMessage(_ message: String) {
        messageLabel.text = message
        messageLabel.isHidden = false
        messageLabel.alpha = 1
        UIView.animate(withDuration: 0.5, delay: TimeInterval(message.count) / 25.0, options: []) {
            self.messageLabel.alpha = 0
        } completion: { _ in
            self.messageLabel.isHidden = true
        }
    }
}


// MARK: - LocationPickerViewControllerDelegate
extension ViewController: LocationPickerViewControllerDelegate {
    func locationPicker(_ viewController: LocationPickerViewController, didSelectLocation location: Location?) {
        if let location = location {
            selectedLocation = location
            locationLabel.text = location.name
        }
        UIView.animate(withDuration: 0.25) {
            self.pickerConstraint.constant = -300
            self.view.layoutIfNeeded()
        }
    }
}
