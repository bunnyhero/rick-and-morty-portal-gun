//
//  Episode.swift
//  RM Data Test
//
//  Created by bunnyhero on 2021-04-30.
//

import Foundation

class Episode: Codable {
    var id: Int = 0
    var name: String = ""
    var airDate: Date?
    var code: String = ""
    var personae: [Persona] = []
}
