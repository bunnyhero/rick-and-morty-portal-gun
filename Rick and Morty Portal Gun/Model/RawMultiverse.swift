//
//  RawMultiverse.swift
//  RM Data Test
//
//  Created by bunnyhero on 2021-05-01.
//

import Foundation
import RickMortySwiftApi

struct RMMultiverse: Codable {
    var version: Int = 0
    var characters: [RMCharacterModel] = []
    var episodes: [RMEpisodeModel] = []
    var locations: [RMLocationModel] = []
}
