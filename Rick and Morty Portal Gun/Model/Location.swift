//
//  Location.swift
//  RM Data Test
//
//  Created by bunnyhero on 2021-04-30.
//

import Foundation

class Location: Codable {
    var id: Int = 0
    var name: String = ""
    var type: String = ""
    var dimension: Dimension?
    var residents: [Persona] = []
}
