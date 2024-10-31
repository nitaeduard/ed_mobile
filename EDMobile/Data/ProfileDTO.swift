//
//  ProfileDTO.swift
//  E:D Mobile
//
//  Created by Eduard Radu Nita on 03/02/2024.
//

import Foundation

struct ProfileDTO: Codable {
    var commander: Commander
    var lastSystem: System?
    var lastStarport: Starport?
    var ship: Ship?
    // var ships: Ships?
    // var loadout: Loudout
    // var loadouts: Loudouts?
    // var suit: Suit?
    // var suits: Suits?
}

struct Starport: Codable {
    var id: Int64
    // var services: []
    var name: String
    var faction: String
    var minorfaction: String
}

struct Suit: Codable {
    var name: String
    var id: Int64
    var suitId: Int64
    var locName: String
    // var slots: []
    var state: SuitState?
}

struct SuitState: Codable {
    var health: SuitHealth?
}

struct Rank: Codable {
    var combat: Int
    var trade: Int
    var explore: Int
    var crime: Int
    var service: Int
    var empire: Int
    var federation: Int
    var power: Int
    var cqc: Int
    var soldier: Int
    var exobiologist: Int
}

struct Commander: Codable {
    var id: Int64
    var name: String
    var credits: Int64
    var debt: Int64
    var currentShipId: Int
    var alive: Bool?
    var docked: Bool
    var onfoot: Bool
    var rank: Rank
}

struct ShipStation: Codable {
    var id: Int64
    var name: String
}

struct ShipValue: Codable {
    var hull: Int64
    var modules: Int64
    var cargo: Int64
    var total: Int64
    var unloaned: Int64
}

struct System: Codable {
    var id: Int64
    var name: String
    var systemaddress: Int64?
    var faction: String?
}

struct Ship: Codable {
    var id: Int
    var name: String
    var free: Bool
    var shipName: String?
    var shipID: String?
    var station: ShipStation?
    var starsystem: System?
    var alive: Bool?
    var value: ShipValue?
    var health: ShipHealth?
    var cockpitBreached: Bool?
    var oxygenRemaining: Int64?
    var LargeHardpoint1: ShipModule?
    var LargeHardpoint2: ShipModule?
    var LargeHardpoint3: ShipModule?
    var LargeHardpoint4: ShipModule?
    var MediumHardpoint1: ShipModule?
    var MediumHardpoint2: ShipModule?
    var MediumHardpoint3: ShipModule?
    var MediumHardpoint4: ShipModule?
    var TinyHardpoint1: ShipModule?
    var TinyHardpoint2: ShipModule?
    var TinyHardpoint3: ShipModule?
    var TinyHardpoint4: ShipModule?
    var Armour: ShipModule?
    var PowerPlant: ShipModule?
    var MainEngines: ShipModule?
    var FrameShiftDrive: ShipModule?
    var LifeSupport: ShipModule?
    var PowerDistributor: ShipModule?
    var Radar: ShipModule?
    var FuelTank: ShipModule?
    var PlanetaryApproachSuite: ShipModule?

    var Slot01_Size6: ShipModule?
    var Slot02_Size6: ShipModule?
    var Slot03_Size5: ShipModule?
    var Slot04_Size5: ShipModule?
    var Slot05_Size4: ShipModule?
    var Slot06_Size3: ShipModule?
    var Slot07_Size3: ShipModule?
    var Slot08_Size2: ShipModule?
    var Slot09_Size1: ShipModule?

    // var PaintJob: PaintJob?
    // var Decal1
    // var Decal2
    // var Decal3
    // var ShipName0
    // var ShipName1
    // var ShipKitSpoiler
    // var ShipKitWings
    // var ShipKitTail
    // var WeaponColour
    // var EngineColour
    // var VesselVoice
}

struct SuitHealth: Codable {
    var hull: Int64
    var shield: Int64?
    var shieldup: Bool?
    var integrity: Int64?
    var paintwork: Int64?
    var scorch: Double?
}

struct ShipHealth: Codable {
    var hull: Int64
    var shield: Int64
    var shieldup: Bool
    var integrity: Int64
    var paintwork: Int64
    var scorch: Double?
}

struct ShipModule: Codable {
    var module: ShipModuleDetails
    var engineer: ShipModuleEngineer?
    // var specialModifications: ShipSpecialModifications? - can also be array?!
}

struct ShipSpecialModifications: Codable {
    var special_thermal_vent: String?
}

struct ShipModuleEngineer: Codable {
    var engineerName: String
    var engineerId: Int64
    var recipeName: String
    var recipeLocName: String
    var recipeLocDescription: String
    var recipeLevel: Int
}

struct ShipModuleDetails: Codable {
    var id: Int64
    var name: String
    var locName: String
    var locDescription: String
    var value: Int64
    var free: Bool
    var health: Int64
    var on: Bool
    var priority: Int
}

struct Ships: Codable {
    var ship0: Ship?
    var ship1: Ship?
    var ship2: Ship?
    var ship3: Ship?
    var ship4: Ship?
    var ship5: Ship?
    var ship6: Ship?
    var ship7: Ship?
    var ship8: Ship?
    var ship9: Ship?

    enum CodingKeys: String, CodingKey {
        case ship0 = "0"
        case ship1 = "1"
        case ship2 = "2"
        case ship3 = "3"
        case ship4 = "4"
        case ship5 = "5"
        case ship6 = "6"
        case ship7 = "7"
        case ship8 = "8"
        case ship9 = "9"
    }
}
