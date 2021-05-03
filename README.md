Rick and Morty Portal Gun
=========================

<!-- MarkdownTOC -->

- Overview
- Planning
    - Network and data layer
        - Considerations
        - Decision
        - Future considerations
        - Furthermore
    - Visualization/UI
- Implementation
    - Network and data layer
        - Issues
            - NSKeyedArchiver
            - Retain cycles
        - Interesting \(?\) details
    - Visualization/UI
- Conclusion
- Legal Info
    - Licensing
    - RickMortySwiftAPI
    - Portal gun 3d model

<!-- /MarkdownTOC -->

Overview
--------

This app lets you view some simple information about the Rick and Morty multiverse using AR. Choose a setting, point the gun at a flat surface, and fire! Tap on any character portrait to find out who it is. Requires an ARKit-capable iPhone.

Planning
--------

### Network and data layer

#### Considerations
* The Rick and Morty data set is relatively small -- in the order of hundreds, not 10s of thousands
  of items
* Does not change often (show not currently airing)
* Even when new season starts airing, there's only one episode/week
* Complex object graph (lots of relationships)
* Would rather focus on visualization logic

#### Decision
* Fetch all data first launch
* Keep entire object graph in memory (not images though)
    * Speed, simplicity
* Persist using NSKeyedArchiver (not Core Data)
    * Simpler, less fussy
* Manual refresh
    * Or at most, refresh if data is more than one day old

#### Future considerations
* If data set becomes much much larger, or changes much much more frequently, re-evaluate

#### Furthermore
* Use Swift library linked to on Rick and Morty API page: [RickMortySwiftAPI](https://github.com/benjaminbruch/Rick-and-Morty-Swift-API)
    * This handles the networking and simple parsing into structs
    * Does not connect references or do any semantics: it's a simple translation from JSON into structs

### Visualization/UI

* There were no specific requirements for this project, except to be imaginative.
* This lack of spec, combined with the limited time, made this feel more like a game jam than a
  typical task, so I approached it like one, with a lot of experimentation and play.
* I did not start with a set app idea in mind, except that I knew I wanted to capture the feel of
  the show in some way.

Implementation
--------------

### Network and data layer

#### Issues

##### NSKeyedArchiver

It had actually been a while since I used `NSKeyedArchiver`, and had not realized that it had not
been updated to work with Swift's `Codable` protocols. It requires the older `NSCoding` protocol.
See discussions on the Swift forums:

- [Codable with references?](https://forums.swift.org/t/codable-with-references/13885)
- [Codable != Archivable](https://forums.swift.org/t/codable-archivable/11414/5)

The amount of boilerplate work to add the `init(coder:)` and `encode(with:)` implementations seemed
daunting and error-prone, especially with the time limitations, so I used a simpler (and much
cruder) solution for now: instead I simply persisted the the flat, raw data emitted by the
RickMortySwiftAPI into a flat file. To restore, the app reloads the flat data and recreates the
object graph from there.

Were I to do this again, I would probably persist with Core Data after all.

##### Retain cycles

For convenience, each relationship between object classes is two-way. Normally the way to avoid
retain cycles in this situation is to use weak references. However, I realized that Swift does not
have a standard collection type for weak references. I considered either implementing my own, or
using an open source one, but I decided that for the parameters of this challenge, I would live
with the retain cycles, since in normal usage, the data never needs to be unloaded. However, in a
situation where the user can refresh the data, all of these retain cycles would have to be broken
manually before releasing the data.

#### Interesting (?) details

While the Rick and Morty API only has types for Characters, Locations, and Episodes, my object
model also includes separate classes for Species and Dimensions. In the Rick and Morty API, these
are simply strings, but I wanted to be able to visualize those relationships as well (unfortunately
I did not end up using these after all).

### Visualization/UI

This part was much less planned, more painful, but also more fun. A mishmash of thoughts:

- Quickly decided I wanted to use the portals in some way
- Then I thought, what about using ARKit to make virtual portals?
    - Upside: this is cool
    - Downside: I had very little experience with ARKit and none with RealityKit
        - Chose RealityKit because it was the newest thing, but it turned out that some things I
          wanted to do were either much more difficult or not yet possible with the current version
- Initial idea was much more ambitious, using portals to enter dimensions, and from there into
  locations, and then to the characters, which would show a detailed information card including
  episode appearances.
- Because I approached this like a game jam, the app is much less polished that I would have liked.
  Ideally there would be instructions, for example, and more feedback about the state of the AR
  session on non-LiDAR-equipped phones.
- Learning on the fly is fun but also, by definition, full of unknowns. There was a lot of frantic
  web searching and trial-and-error

Conclusion
----------

Overall I'm happy with how this turned out, despite the lack of polish and severely limited feature
set of the app. Had I not approached this like a game jam, the code would have probably been
cleaner, more elegant, and better tested, but the app might have been more boring.

Legal Info
----------

### Licensing

See [LICENCE.txt](./LICENCE.txt).

### RickMortySwiftAPI

MIT License

Copyright (c) 2020 Benjamin Bruch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### Portal gun 3d model

"Portal gun (Rick and Morty)" (https://skfb.ly/6U9w7) by kreems is licensed under Creative Commons Attribution (http://creativecommons.org/licenses/by/4.0/).

