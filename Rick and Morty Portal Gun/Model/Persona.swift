//
//  Persona.swift
//  RM Data Test
//
//  Created by bunnyhero on 2021-04-30.
//

import Foundation

class Persona: Codable {
    enum Status: String, Codable {
        case alive
        case dead
        case unknown
    }
    enum Gender: String, Codable {
        case female
        case male
        case genderless
        case unknown
    }
    var id: Int = 0
    var name: String = ""
    var status: Status = .unknown
    var species: Species?
    var gender: Gender = .unknown
    var imageUrl: URL?
    weak var origin: Location?
    weak var location: Location?
    var episodes: [Episode] = [] // These refs will have to be manually nil'd out before release
}
