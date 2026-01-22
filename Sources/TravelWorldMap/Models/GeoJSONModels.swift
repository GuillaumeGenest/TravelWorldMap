//
//  File.swift
//  TravelWorldMap
//
//  Created by Guillaume on 20/01/2026.
//

import Foundation

struct GeoJSONFeatureCollection: Codable {
    let type: String
    let features: [GeoJSONFeature]
}

struct GeoJSONFeature: Codable {
    let type: String
    let properties: GeoJSONProperties
    let geometry: GeoJSONGeometry
}

struct GeoJSONProperties: Codable {
    let name: String?
    let isoA3: String?
    let isoA2: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case isoA3 = "ISO3166-1-Alpha-3"
        case isoA2 = "ISO3166-1-Alpha-2"
    }
}

struct GeoJSONGeometry: Codable {
    let type: String
    let coordinates: [[[Double]]]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        if type == "Polygon" {
            let polygon = try container.decode([[[Double]]].self, forKey: .coordinates)
            coordinates = polygon
        } else if type == "MultiPolygon" {
            let multiPolygon = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            coordinates = multiPolygon.flatMap { $0 }
        } else {
            coordinates = []
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
}
