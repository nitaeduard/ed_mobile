//
//  StarSceneView.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 05/10/2024.
//

import CoreImage
import Foundation
import GameplayKit
import SceneKit
import SwiftUI
#if canImport(UIKit)
    import UIKit

    typealias EDViewRepresentable = UIViewRepresentable
    typealias EDColor = UIColor
    typealias EDImage = UIImage
#else
    import AppKit

    typealias EDViewRepresentable = NSViewRepresentable
    typealias EDColor = NSColor
    typealias EDImage = NSImage
#endif

enum EDStarType {
    case redDwarf, yellowDwarf, whiteDwarf, blueGiant, supergiant
}

struct EDStarSceneView: EDViewRepresentable {
    var starType: EDStarType

    func makeUIView(context: Context) -> SCNView {
        createUI()
    }

    func makeNSView(context: Context) -> SCNView {
        createUI()
    }

    private func createUI() -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .black
        sceneView.antialiasingMode = .multisampling2X

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        sceneView.scene?.rootNode.addChildNode(cameraNode)

        let starNode = createStar(starType: starType)

        addPulsationEffect(to: starNode)

        sceneView.scene?.rootNode.addChildNode(starNode)
        starNode.position = .init(0, 0, 0)

        let bloomFilter = CIFilter(name: "CIBloom")!
        bloomFilter.setValue(150.0, forKey: kCIInputRadiusKey)
        bloomFilter.setValue(0.2, forKey: kCIInputIntensityKey)
        sceneView.scene?.rootNode.filters = [bloomFilter]

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) { }
    func updateNSView(_ uiView: SCNView, context: Context) { }

    func createStar(starType: EDStarType) -> SCNNode {
        let sphere = SCNSphere(radius: starType.radius)

        let material = SCNMaterial()

        let program = SCNProgram()
        let image = generateStarSurfaceTexture(size: CGSize(width: 512, height: 512))
        let imageProperty = SCNMaterialProperty(contents: image)
        program.vertexFunctionName = "vertexShader"
        program.fragmentFunctionName = "coronaGlow"
        material.program = program
        material.setValue(imageProperty, forKey: "diffuseTexture")
        material.lightingModel = .constant
        sphere.firstMaterial = material

        return SCNNode(geometry: sphere)
    }

    func addPulsationEffect(to starNode: SCNNode) {
        let pulsationAction = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 1.0, duration: 1.5),
            SCNAction.fadeOpacity(to: 0.8, duration: 1.5)
        ])
        let repeatAction = SCNAction.repeatForever(pulsationAction)
        starNode.runAction(repeatAction)
    }

    func generateStarSurfaceTexture(size: CGSize) -> EDImage {
        #if canImport(UIKit)
            UIGraphicsBeginImageContext(size)
            guard let context = UIGraphicsGetCurrentContext() else {
                return EDImage()
            }
        #else
            guard let context = NSGraphicsContext() else {
                return EDImage()
            }
        #endif

        let noiseSource = GKPerlinNoiseSource(
            frequency: starType.frequency,
            octaveCount: 6,
            persistence: 0.7,
            lacunarity: 2.0,
            seed: Int32.random(in: 0 ..< 1000)
        )

        let noise = GKNoise(noiseSource)
        let noiseMap = GKNoiseMap(noise, size: vector2(1.0, 1.0), origin: vector2(0.0, 0.0), sampleCount: vector2(Int32(size.width), Int32(size.height)), seamless: true)

        let width = Int(size.width)
        let height = Int(size.height)
        let ciColor = starType.color.cgColor.components!

        for y in 0 ..< height {
            for x in 0 ..< width {
                let noiseValue = noiseMap.value(at: vector2(Int32(x), Int32(y)))

                let colorValue = CGFloat((noiseValue + 1.0) / 2.0) * starType.noiseMultiplier

                let color = EDColor(
                    red: ciColor[0] + colorValue,
                    green: ciColor[1] + colorValue,
                    blue: ciColor[2] + colorValue,
                    alpha: 1.0)

                #if canImport(UIKit)
                    context.setFillColor(color.cgColor)
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                #else
                    context.cgContext.setFillColor(color.cgColor)
                    context.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                #endif
            }
        }

        #if canImport(UIKit)
            let starSurfaceTexture = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext()

            return starSurfaceTexture
        #else
            if let texture = context.cgContext.makeImage() {
                return EDImage(cgImage: texture, size: size)
            }
            return EDImage()
        #endif
    }
}

extension EDStarType {
    var frequency: CGFloat {
        switch self {
        case .blueGiant: return 1000.0
        case .redDwarf: return 10
        case .supergiant: return 500
        case .whiteDwarf: return 10
        case .yellowDwarf: return 10
        }
    }

    var noiseMultiplier: CGFloat {
        switch self {
        case .blueGiant: return 0.7
        case .redDwarf: return 0.1
        case .supergiant: return 50
        case .whiteDwarf: return 0.3
        case .yellowDwarf: return 0.1
        }
    }

    var radius: CGFloat {
        switch self {
        case .redDwarf: return 2.5
        case .yellowDwarf: return 2.5
        case .whiteDwarf: return 2.5
        case .blueGiant: return 2.5
        case .supergiant: return 2.5
        }
    }

    var color: EDColor {
        switch self {
        case .redDwarf: return EDColor(red: 255 / 255, green: 90 / 255, blue: 71 / 255, alpha: 1.0)
        case .yellowDwarf: return EDColor.yellow
        case .whiteDwarf: return EDColor(red: 240 / 255, green: 240 / 255, blue: 240 / 255, alpha: 1.0)
        case .blueGiant: return EDColor(red: 72 / 255, green: 160 / 255, blue: 255 / 255, alpha: 1.0)
        case .supergiant: return EDColor.orange
        }
    }

    var temperature: Double {
        switch self {
        case .redDwarf: return 3000 // in Kelvin
        case .yellowDwarf: return 5500
        case .whiteDwarf: return 10000
        case .blueGiant: return 25000
        case .supergiant: return 30000
        }
    }

    var luminosity: CGFloat {
        switch self {
        case .redDwarf: return 0.1
        case .yellowDwarf: return 1.0
        case .whiteDwarf: return 0.01
        case .blueGiant: return 100
        case .supergiant: return 1000
        }
    }
}

#Preview {
    EDStarSceneView(starType: .yellowDwarf)
        .ignoresSafeArea()
}
