//
//  File.swift
//  TravelWorldMap
//
//  Created by Guillaume on 20/01/2026.
//

import Foundation
import CoreLocation

public final class Country: Identifiable, Codable, Hashable, @unchecked Sendable {
    public let id: String
    public let name: String
    public let isoA3: String
    public let coordinates: [[[Double]]]

    public lazy var polygons: [[CLLocationCoordinate2D]] = {
        coordinates.map { polygon in
            polygon.map { coord in
                CLLocationCoordinate2D(
                    latitude: coord[1],
                    longitude: coord[0]
                )
            }
        }
    }()

    public init(id: String, name: String, isoA3: String, coordinates: [[[Double]]]) {
        self.id = id
        self.name = name
        self.isoA3 = isoA3
        self.coordinates = coordinates
    }

    public var polygonCount: Int {
        polygons.count
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Country, rhs: Country) -> Bool {
        lhs.id == rhs.id
    }
}
