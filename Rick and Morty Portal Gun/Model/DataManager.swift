//
//  DataManager.swift
//  RM Data Test
//
//  Created by bunnyhero on 2021-04-30.
//

import os
import Foundation
import RickMortySwiftApi
import Combine

class DataManager {
    static let shared = DataManager()
    
    var persistenceUrl: URL = {
        do {
            let cacheUrl = try FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            return cacheUrl.appendingPathComponent("multiverse.json")
        } catch {
            fatalError("Could not find cache directory")
        }
    }()
    
    var multiverse: Multiverse!
    
    private var rmClient = RMClient()
    private var cancellable: AnyCancellable?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "DataManager")
    
    init() {
    }
    
    /// Loads the multiverse, trying local cached data first, then fetching from servers if no cache
    /// - Parameter completion: completion handler called when data has been loaded
    func loadMultiverse(then completion: ((Multiverse) -> Void)? = nil) {
        if let multiverse = restoreMultiverse() {
            self.multiverse = multiverse
            completion?(multiverse)
            return
        }
        
        downloadMultiverse { multiverse in
            self.multiverse = multiverse
            completion?(multiverse)
        }
    }
    
    
    private func downloadMultiverse(then completion: @escaping ((Multiverse) -> Void)) {
        let characterPublisher = rmClient.character().getAllCharacters().replaceError(with: [])
        let episodePublisher = rmClient.episode().getAllEpisodes().replaceError(with: [])
        let locationPublisher = rmClient.location().getAllLocations().replaceError(with: [])
        
        cancellable = Publishers.Zip3(characterPublisher, episodePublisher, locationPublisher)
            .sink { [weak self](characters, episodes, locations) in
                guard let self = self else { return }
                // Cache what we get
                self.saveRawMultiverse(characters: characters, episodes: episodes, locations: locations)
                let multiverse = self.createMultiverseFromRaw(
                    characters: characters, episodes: episodes, locations: locations
                )
                DispatchQueue.main.async {
                    completion(multiverse)
                }
            }
    }
    

    private func saveRawMultiverse(
        characters: [RMCharacterModel], episodes: [RMEpisodeModel], locations: [RMLocationModel]
    ) {
        logger.debug("attempting to encode and save fetched data")
        var rawMultiverse = RMMultiverse()
        rawMultiverse.characters = characters
        rawMultiverse.episodes = episodes
        rawMultiverse.locations = locations
        
        do {
            let data = try JSONEncoder().encode(rawMultiverse)
            try data.write(to: persistenceUrl)
            logger.debug("wrote data")
        }
        catch {
            debugPrint(error)
        }
    }

    
    private func restoreMultiverse() -> Multiverse? {
        logger.debug("attempting to restore cached data")
        do {
            let data = try Data(contentsOf: persistenceUrl)
            let rawMultiverse = try JSONDecoder().decode(RMMultiverse.self, from: data)
            let multiverse = createMultiverseFromRaw(
                characters: rawMultiverse.characters,
                episodes: rawMultiverse.episodes,
                locations: rawMultiverse.locations
            )
            logger.debug("successfully (?) restored cached data")
           return multiverse
        }
        catch {
            debugPrint(error)
            return nil
        }
    }

    
    /// Creates in-memory cross-referenced multiverse objects based on the raw flat JSON data
    /// - Parameters:
    ///   - characters: array of flat character data
    ///   - episodes: array of flat episode data
    ///   - locations: array of flat location data
    /// - Returns: build multiverse
    private func createMultiverseFromRaw(
        characters: [RMCharacterModel], episodes: [RMEpisodeModel], locations: [RMLocationModel]
    ) -> Multiverse {
        // This is a two-step process. First we create all of the in-memory objects so we know
        // that all referents exist. Then we can hook them up
        let multiverse = createUnconnectedMultiverseFromRaw(
            characters: characters, episodes: episodes, locations: locations
        )
        connectMultiverseReferences(
            multiverse: multiverse, characters: characters, episodes: episodes, locations: locations
        )
        return multiverse
    }
    
    private func createUnconnectedMultiverseFromRaw(
        characters: [RMCharacterModel], episodes: [RMEpisodeModel], locations: [RMLocationModel]
    ) -> Multiverse {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, YYYY"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let multiverse = Multiverse()
        // Create all the object models *without* connecting them
        // Collect species names here too
        var speciesNames = Set<String>()
        for char in characters {
            let persona = Persona()
            persona.id = char.id
            persona.name = char.name
            persona.status = Persona.Status(rawValue: char.status) ?? .unknown
            persona.gender = Persona.Gender(rawValue: char.gender) ?? .unknown
            persona.imageUrl = URL(string: char.image)
            multiverse.personae.append(persona)
            speciesNames.insert(char.species)
        }
        // Create species based on name
        for speciesName in speciesNames {
            let species = Species()
            species.name = speciesName
            multiverse.species.append(species)
        }
        for rawEpisode in episodes {
            let episode = Episode()
            episode.id = rawEpisode.id
            episode.name = rawEpisode.name
            episode.code = rawEpisode.episode
            episode.airDate = dateFormatter.date(from: rawEpisode.airDate)
            multiverse.episodes.append(episode)
        }
        // Also collect dimension names
        var dimensionNames = Set<String>()
        for rawLocation in locations {
            let location = Location()
            location.id = rawLocation.id
            location.name = rawLocation.name
            multiverse.locations.append(location)
            dimensionNames.insert(rawLocation.dimension)
        }
        // Create dimensions based on name
        for dimensionName in dimensionNames {
            let dimension = Dimension()
            dimension.name = dimensionName
            multiverse.dimensions.append(dimension)
        }
        return multiverse
    }
    
    
    private func connectMultiverseReferences(
        multiverse: Multiverse,
        characters: [RMCharacterModel],
        episodes: [RMEpisodeModel],
        locations: [RMLocationModel]
    ) {
        logger.debug("Connecting references")
        
        // Make some lookup tables
        var personaById = [Int: Persona]()
        var episodeById = [Int: Episode]()
        var locationById = [Int: Location]()
        var dimensionByName = [String: Dimension]()
        var speciesByName = [String: Species]()
        
        for persona in multiverse.personae {
            personaById[persona.id] = persona
        }
        for episode in multiverse.episodes {
            episodeById[episode.id] = episode
        }
        for location in multiverse.locations {
            locationById[location.id] = location
        }
        for dimension in multiverse.dimensions {
            dimensionByName[dimension.name] = dimension
        }
        for species in multiverse.species {
            speciesByName[species.name] = species
        }
        logger.debug("Connecting characters")
        // Connect character outlets
        for rawCharacter in characters {
            guard let persona = personaById[rawCharacter.id] else {
                logger.error("  ** No persona with id \(rawCharacter.id, privacy: .public)")
                continue
            }
            logger.debug("  Processing character id \(rawCharacter.id, privacy: .public)")
            if let locationId = parseId(fromUrlString: rawCharacter.origin.url) {
                persona.origin = locationById[locationId]
            }
            if let locationId = parseId(fromUrlString: rawCharacter.location.url) {
                persona.location = locationById[locationId]
            }
            if let species = speciesByName[rawCharacter.species] {
                persona.species = species
                species.personae.append(persona)
            } else {
                logger.error("    ** Missing species for name = \(rawCharacter.species, privacy: .public)")
            }
            for episodeUrl in rawCharacter.episode {
                if let episodeId = parseId(fromUrlString: episodeUrl), let episode = episodeById[episodeId] {
                    persona.episodes.append(episode)
                }
            }
        }
        // Connect episode outlets, and verify by checking that reverse character direction was already hooked up
        logger.debug("Connecting episodes")
        for rawEpisode in episodes {
            guard let episode = episodeById[rawEpisode.id] else {
                logger.error("  ** No episode with id \(rawEpisode.id, privacy: .public)")
                continue
            }
            logger.debug("  Processing episode id \(rawEpisode.id, privacy: .public)")
            for characterUrl in rawEpisode.characters {
                if let characterId = parseId(fromUrlString: characterUrl) {
                    guard let persona = personaById[characterId] else {
                        logger.error("    ** Missing persona for ID = \(characterId, privacy: .public)")
                        continue
                    }
                    episode.personae.append(persona)
                    // Sanity check back-connection exists
                    if !persona.episodes.contains(where: { $0.id == episode.id }) {
                        logger.error(
                            "    ** Connection mismatch between character ID \(persona.id, privacy: .public) and episode ID \(episode.id, privacy: .public)"
                        )
                    }
                }
            }
        }
        // Connect location outlets, verifying back connections
        logger.debug("Connecting locations")
        for rawLocation in locations {
            guard let location = locationById[rawLocation.id] else {
                logger.error("  ** No location with id \(rawLocation.id, privacy: .public)")
                continue
            }
            logger.debug("  Processing location id \(rawLocation.id, privacy: .public)")
            if let dimension = dimensionByName[rawLocation.dimension] {
                location.dimension = dimension
                dimension.locations.append(location)
            } else {
                logger.error("    ** Missing dimension for name = \(rawLocation.dimension, privacy: .public)")
            }
            for rawResidentUrl in rawLocation.residents {
                if let characterId = parseId(fromUrlString: rawResidentUrl) {
                    guard let persona = personaById[characterId] else {
                        logger.error("    ** Missing persona for ID = \(characterId, privacy: .public)")
                        continue
                    }
                    location.residents.append(persona)
                    // Sanity check back-connection exists
                    if persona.location !== location {
                        logger.error(
                            "    ** Connection mismatch between character ID \(persona.id, privacy: .public) and location ID \(location.id, privacy: .public)"
                        )
                    }
                }
            }
        }
    }

    private func parseId(fromUrlString urlString: String) -> Int? {
        urlString.components(separatedBy: "/").last.flatMap({ Int($0) })
    }
}
