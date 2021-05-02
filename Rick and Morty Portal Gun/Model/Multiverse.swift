//
//  Multiverse.swift
//  RM Data Test
//
//  Created by bunnyhero on 2021-04-30.
//

import Foundation

class Multiverse: Codable {
    var personae: [Persona] = []
    var episodes: [Episode] = []
    var locations: [Location] = []
    var dimensions: [Dimension] = []
    var species: [Species] = []
}
