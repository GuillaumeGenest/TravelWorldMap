//
//  File.swift
//  TravelWorldMap
//
//  Created by Guillaume on 20/01/2026.
//

import Foundation

public final class CountryDataLoader: @unchecked Sendable {
    public static let shared = CountryDataLoader()
    
    private var countries: [Country] = []
    
    private init() {
        loadCountries()
    }
    
    private func loadCountries() {
            guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson") else {
                print("❌ Fichier countries.geojson non trouvé dans le bundle principal")
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let geoJSON = try decoder.decode(GeoJSONFeatureCollection.self, from: data)
                
                countries = geoJSON.features.compactMap { feature -> Country? in
                    guard let name = feature.properties.name else {
                        return nil
                    }
                    
                    let isoA2 = feature.properties.isoA2
                    let isoA3 = feature.properties.isoA3
                    
                    let id: String
                    if let isoA2, isoA2 != "-99", !isoA2.isEmpty {
                        id = isoA2
                    } else {
                        id = name
                            .uppercased()
                            .replacingOccurrences(of: " ", with: "_")
                    }
                    return Country(
                        id: id,
                        name: name,
                        isoA3: (isoA3 != "-99") ? (isoA3 ?? "") : "",
                        coordinates: feature.geometry.coordinates
                    )
                }
                countries.sort { $0.name < $1.name }
                
                print("✅ \(countries.count) pays chargés avec succès")
                if let norway = countries.first(where: { $0.name == "Norway" }) {
                    print("🇳🇴 Norway chargé – id: \(norway.id)")
                }
                if let kosovo = countries.first(where: { $0.name == "Kosovo" }) {
                    print("🇽🇰 Kosovo chargé – id: \(kosovo.id)")
                }
            } catch {
                print("❌ Erreur de chargement du GeoJSON: \(error)")
                if let decodingError = error as? DecodingError {
                    print("Détails : \(decodingError)")
                }
            }
        }
    
    public func getAllCountries() -> [Country] {
        return countries
    }
    
    public func getCountry(byCode code: String) -> Country? {
        return countries.first { $0.id.uppercased() == code.uppercased() }
    }
    
    public func getCountry(byName name: String) -> Country? {
        return countries.first { $0.name.lowercased() == name.lowercased() }
    }
    
    public func searchCountries(query: String) -> [Country] {
        guard !query.isEmpty else { return countries }
        let lowercaseQuery = query.lowercased()
        return countries.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.id.lowercased().contains(lowercaseQuery) ||
            $0.isoA3.lowercased().contains(lowercaseQuery)
        }
    }
    
    public func getCountriesByContinent() -> [String: [Country]] {
        // TODO: Ajouter les continents dans le futur si nécessaire
        return ["All": countries]
    }
}
