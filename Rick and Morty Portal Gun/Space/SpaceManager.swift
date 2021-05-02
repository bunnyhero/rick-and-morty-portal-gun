//
//  SpaceManager.swift
//  RKTest
//
//  Created by bunnyhero on 2021-05-02.
//

import ARKit
import RealityKit

class SpaceManager {
    weak var arView: ARView!
    
    var portals: [Portal] = []
    var cards: [PersonaCard] = []
    
    init(arView: ARView) {
        self.arView = arView
        PersonaCardComponent.registerComponent()
    }
    
    func shootPortal(into location: Location) -> Bool {
        let results = arView.raycast(
            from: CGPoint(x: arView.bounds.width / 2, y: arView.bounds.height / 2),
            allowing: .existingPlaneGeometry,
            alignment: .any
        )
        guard let result = results.first else { return false }

        let portal = Portal.createPortal(at: result.worldTransform, into: location)
        arView.scene.addAnchor(portal.anchorEntity)
        portals.append(portal)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.spawnCards(portal: portal)
        }
        
        // Too many portals? Start removing some
        if portals.count > 4 {
            let portalToRemove = portals.removeFirst()
            // Remove any cards that belonged to that portal
            cards = cards.filter({ $0.rootEntity.parent != portalToRemove.anchorEntity})
            arView.scene.removeAnchor(portalToRemove.anchorEntity)
        }
        return true
    }
    
    func spawnCards(portal: Portal) {
        for (index, persona) in portal.location.residents.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(index) * 0.5) {
                let card = PersonaCard(persona: persona)
                card.load()
                // pick a random position in a disc
                let angle = Float.random(in: 0..<Float.pi * 2)
                let magnitude = Float.random(in: 0..<0.25)
                card.rootEntity.position = [cos(angle) * magnitude, 0, sin(angle) * magnitude]
                portal.anchorEntity.addChild(card.rootEntity)
                // orient it to world space
                card.rootEntity.setOrientation(simd_quatf(angle: 0, axis: [1, 0, 0]), relativeTo: nil)
                // shrink it down a little
                card.rootEntity.scale = [0.1, 0.1, 0.1]
                var targetTransform = card.rootEntity.transform
                targetTransform.translation *= 3
                targetTransform.translation.y = Float.random(in: 0.5..<1)
                targetTransform.scale = [1.0, 1.0, 1.0]
                card.rootEntity.move(to: targetTransform, relativeTo: portal.anchorEntity, duration: 2.0)
                card.startSpin()
                self.cards.append(card)
            }
        }
    }
    
}

