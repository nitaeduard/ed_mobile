//
//  PlanetSceneView.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 06/10/2024.
//

import GameplayKit
import QuartzCore
import SceneKit
import SwiftUI

struct EDPlanetSceneView: EDViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        createView()
    }

    func makeNSView(context: Context) -> SCNView {
        createView()
    }

    private func createView() -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = EDColor.black

        // Create Scene
        let scene = SCNScene()
        scnView.scene = scene

        // Create Planet Node
        let planetNode = createPlanet()
        scene.rootNode.addChildNode(planetNode)

        // Add Stars background
        let starsNode = createStaticStars()
        starsNode.position = .init(0, 0, -3)
        scene.rootNode.addChildNode(starsNode)

        // Setup Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 10)
        scene.rootNode.addChildNode(cameraNode)

//        // Add lighting
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light?.type = .omni
//        lightNode.position = SCNVector3(0, 10, 10)
//        scene.rootNode.addChildNode(lightNode)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) { }

    func updateNSView(_ nsView: SCNView, context: Context) {}

    // Function to create the planet
    func createPlanet() -> SCNNode {
        let planetGeometry = SCNSphere(radius: 1.1)
        let material = SCNMaterial()

        let shaderProgram = SCNProgram()
        shaderProgram.vertexFunctionName = "planetVertexShader"
        shaderProgram.fragmentFunctionName = "planetFragmentShader"
        material.program = shaderProgram
        planetGeometry.firstMaterial = material

        let planetNode = SCNNode(geometry: planetGeometry)
        let atmosphereNode = createAtmosphere()
        planetNode.addChildNode(atmosphereNode)

        return planetNode
    }

//    // Function to create procedural texture
//    func generatePlanetTexture() -> UIImage {
//        let size = CGSize(width: 512, height: 512)
//        let renderer = UIGraphicsImageRenderer(size: size)
//
//        let noiseSource = GKPerlinNoiseSource(
//            frequency: 100,
//            octaveCount: 6,
//            persistence: 0.7,
//            lacunarity: 2.0,
//            seed: Int32.random(in: 0 ..< 1000)
//        )
//
//        let noise = GKNoise(noiseSource)
//        let noiseMap = GKNoiseMap(noise,
//                                  size: vector2(1.0, 1.0),
//                                  origin: vector2(0.0, 0.0),
//                                  sampleCount: vector2(Int32(size.width), Int32(size.height)),
//                                  seamless: true)
//
//        let width = Int(size.width)
//        let height = Int(size.height)
//        let ciColor = UIColor.blue.cgColor.components!
//
//        let image = renderer.image { context in
//
//            for y in 0 ..< height {
//                for x in 0 ..< width {
//                    let noiseValue = noiseMap.value(at: vector2(Int32(x), Int32(y)))
//
//                    let colorValue = CGFloat((noiseValue + 1.0) / 2.0) * 0.5
//
//                    let color = UIColor(
//                        red: ciColor[0] + colorValue,
//                        green: ciColor[1] + colorValue,
//                        blue: ciColor[2] + colorValue,
//                        alpha: 1.0)
//
//                    context.cgContext.setFillColor(color.cgColor)
//                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
//                }
//            }
//        }
//
//        return image
//    }

    // Function to create the atmosphere
    func createAtmosphere() -> SCNNode {
        let atmosphereGeometry = SCNSphere(radius: 1.2)
        let atmosphereMaterial = SCNMaterial()
        atmosphereMaterial.diffuse.contents = EDColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.01)
        atmosphereMaterial.blendMode = .add
        atmosphereGeometry.firstMaterial = atmosphereMaterial
        return SCNNode(geometry: atmosphereGeometry)
    }

    func createStars() -> SCNNode {
        let starNode = SCNNode()

        let stars = SCNParticleSystem()
        stars.birthRate = 5
        stars.birthLocation = .volume
        stars.birthRateVariation = 100
        stars.emitterShape = SCNSphere(radius: 4)
        stars.particleSize = 0.005
        stars.blendMode = .additive
        stars.particleColor = EDColor.blue
        stars.particleLifeSpan = 20.0
        stars.acceleration = .init(0, 0, 1)
        starNode.addParticleSystem(stars)

        return starNode
    }

    func createStaticStars() -> SCNNode {
        let starNode = SCNNode()

        let stars = SCNParticleSystem()
        stars.birthRate = 5
        stars.birthLocation = .surface
        stars.birthRateVariation = 100
        stars.emitterShape = SCNBox(width: 6, height: 15, length: 2, chamferRadius: 0)
        stars.particleSize = 0.01
        stars.blendMode = .additive
        stars.particleColor = EDColor.blue
        stars.particleLifeSpan = 5.0
//        stars.acceleration = .init(0, 0, 1)
        starNode.addParticleSystem(stars)

        return starNode
    }
}

#Preview {
    EDPlanetSceneView()
        .ignoresSafeArea()
}
