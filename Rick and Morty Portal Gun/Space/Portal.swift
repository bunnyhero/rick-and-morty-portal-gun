//
//  Portal.swift
//  RKTest
//
//  Created by bunnyhero on 2021-05-02.
//

import UIKit
import AVFoundation
import RealityKit

class Portal {
    var anchorEntity: AnchorEntity!
    var modelEntity: ModelEntity!
    var textEntity: ModelEntity!
    var player: AVPlayer!
    weak var location: Location!
    
    var name: String = ""
    
    init(at worldTransform: simd_float4x4, into location: Location) {
        // The portal is a square with rounded corners (i.e. a circle), textured with a video
        let discMesh = MeshResource.generatePlane(width: 0.5, depth: 0.5, cornerRadius: 0.25)
        let asset = AVURLAsset(url: Bundle.main.url(forResource: "portal", withExtension: "mov")!)
        let playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer()
        let material = VideoMaterial(avPlayer: player)
        
        modelEntity = ModelEntity(mesh: discMesh, materials: [material])
        anchorEntity = AnchorEntity(world: worldTransform)
        anchorEntity.addChild(modelEntity)
        
        // We don't have flat decals but we can make 3D-extruded text
        self.location = location
        let font = UIFont(name: "Baloo", size: 0.1) ?? UIFont.systemFont(ofSize: 0.1)
        let textMesh = MeshResource.generateText(
            location.name,
            extrusionDepth: 0.01,
            font: font,
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let textMaterial = SimpleMaterial(color: .green, roughness: 0.5, isMetallic: true)
        textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // Position the text entity properly
        textEntity.transform = Transform(
            scale: [1, 1, 1],
            rotation: simd_quaternion(-.pi / 2, [1, 0, 0]),
            translation: [-textMesh.bounds.extents.x / 2, 0.05, 0.25]
        )
        
        anchorEntity.addChild(textEntity)
        
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }
    
    static func createPortal(at worldTransform: simd_float4x4, into location: Location) -> Portal {
        return Portal(at: worldTransform, into: location)
    }
}
