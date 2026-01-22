//
//  File.swift
//  TravelWorldMap
//
//  Created by Guillaume on 20/01/2026.
//

import Foundation
import CoreLocation
import MapKit

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

extension Country {
    func getVisiblePolygonIndices(in region: MKCoordinateRegion) -> [Int] {
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        
        return polygons.indices.filter { index in
            let polygon = polygons[index]
            
            return polygon.contains { coord in
                coord.latitude >= minLat &&
                coord.latitude <= maxLat &&
                coord.longitude >= minLon &&
                coord.longitude <= maxLon
            }
        }
    }
    
    func withFilteredPolygons(_ indices: [Int]) -> Country {
        let filteredCoordinates = indices.map { coordinates[$0] }
        return Country(
            id: self.id,
            name: self.name,
            isoA3: self.isoA3,
            coordinates: filteredCoordinates
        )
    }
}
