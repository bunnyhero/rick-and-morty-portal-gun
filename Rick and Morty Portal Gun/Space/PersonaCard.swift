//
//  PersonaCard.swift
//  RKTest
//
//  Created by bunnyhero on 2021-05-03.
//

import os
import Combine
import Foundation
import RealityKit

class PersonaCard {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PersonaCard")
    
    /// Separate root to make it easier to spin the card independently of its translation
    var rootEntity: Entity!
    var modelEntity: ModelEntity!
    weak var persona: Persona!
    
    private var mesh: MeshResource!
    
    private var cancellable: Cancellable?
    private var spinPhase: Int = 0

    init(persona: Persona) {
        self.persona = persona
        
        // Use a placeholder black material until the image is loaded
        let material = SimpleMaterial(color: .black, isMetallic: false)
        mesh = MeshResource.generateBox(width: 0.20, height: 0.20, depth: 0.01)
        let collisionShape = ShapeResource.generateBox(width: 0.20, height: 0.20, depth: 0.01)
        modelEntity = ModelEntity(mesh: mesh, materials: [material], collisionShape: collisionShape, mass: 0.1)
        modelEntity.physicsBody?.mode = .kinematic
        modelEntity.components[PersonaCardComponent.self] = PersonaCardComponent(personaCard: self)
        
        rootEntity = Entity()
        rootEntity.addChild(modelEntity)
    }
    
    func load() {
        guard let url = persona.imageUrl else { return }
        ImageDownloader.shared.getLocalImageUrl(fromRemoteUrl: url) { result in
            switch result {
            case .success(let fileUrl):
                if let textureResource = try? TextureResource.load(contentsOf: fileUrl) {
                    PersonaCard.logger.debug("success!")
                    // make a new model with that material and use that
                    var material = SimpleMaterial()
                    material.baseColor = .texture(textureResource)
                    self.modelEntity.model = ModelComponent(mesh: self.mesh, materials: [material])
                }
                else {
                    PersonaCard.logger.debug("no texture for you!")
                }
            case .failure(let error):
                PersonaCard.logger.error("\(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Starts the spin animation
    func startSpin() {
        // RealityKit has no looping/infinite animation if the animation is created in code.
        // Listen for 'PlaybackCompleted' events so we can pick up where we left off.
        // We can't even specify a 360-degree rotation, because that's interpreted as a zero rotation.
        // Do this 90 degrees at a time.
        
        var targetTransform = modelEntity.transform
        spinPhase += 1
        targetTransform.rotation = simd_quatf(angle: Float(spinPhase) * .pi / 4, axis: [0, 1, 0])
        let animationController = modelEntity.move(
            to: targetTransform, relativeTo: modelEntity.parent, duration: 1.0, timingFunction: .linear
        )
        
        let cancellable = modelEntity.scene?.subscribe(
            to: AnimationEvents.PlaybackCompleted.self, on: modelEntity
        ) { event in
            if event.playbackController == animationController {
                // Do the next 90 degrees
                DispatchQueue.main.async {
                    if self.cancellable != nil {
                        self.startSpin()
                    }
                }
            }
        }
        self.cancellable = cancellable
    }
    
    func stopSpin() {
        cancellable?.cancel()
        cancellable = nil
    }
}

struct PersonaCardComponent: Component {
    weak var personaCard: PersonaCard?
}
