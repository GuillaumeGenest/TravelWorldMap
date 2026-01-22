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
        guard let url = Bundle.module.url(forResource: "countries", withExtension: "geojson") else {
            print("❌ Fichier countries.geojson non trouvé dans Resources")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let geoJSON = try decoder.decode(GeoJSONFeatureCollection.self, from: data)
            
            countries = geoJSON.features.compactMap { feature -> Country? in
                // Utiliser les nouvelles clés du JSON
                guard let isoA2 = feature.properties.isoA2,
                      let name = feature.properties.name,
                      let isoA3 = feature.properties.isoA3,
                      !isoA2.isEmpty else {
                    return nil
                }
                
                return Country(
                    id: isoA2,
                    name: name,
                    isoA3: isoA3,
                    coordinates: feature.geometry.coordinates
                )
            }
            
            // Tri par nom pour faciliter la recherche
            countries.sort { $0.name < $1.name }
            
            print("✅ \(countries.count) pays chargés avec succès")
            
            // Debug : afficher quelques exemples
            if let chile = countries.first(where: { $0.id == "CL" }) {
                print("🇨🇱 Chile : \(chile.polygonCount) polygone(s)")
            }
            if let france = countries.first(where: { $0.id == "FR" }) {
                print("🇫🇷 France : \(france.polygonCount) polygone(s)")
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
