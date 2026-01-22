//
//  File.swift
//  TravelWorldMap
//
//  Created by Guillaume on 20/01/2026.
//


import Foundation
import SwiftUI
import MapKit

public struct WorldMapView: View {

    private let visitedCountryCodes: Set<String>
    private let visitedColor: Color
    private let unvisitedColor: Color
    private let strokeColor: Color
    private let strokeWidth: CGFloat
    
    private let maxPointsPerPolygon: Int
    private let enableRegionOptimization: Bool
    private let interactionModes: MapInteractionModes
    private let initialRegion: MKCoordinateRegion
    
    @State private var allCountries: [Country] = []
    @State private var visibleCountries: [Country] = []
    @State private var position: MapCameraPosition
    @State private var currentRegion: MKCoordinateRegion?
    
    // MARK: - Initialiseurs
    public init(
        visitedCountryCodes: Set<String>,
        visitedColor: Color = .blue,
        unvisitedColor: Color = .gray,
        strokeColor: Color = .white,
        strokeWidth: CGFloat = 0.5,
        maxPointsPerPolygon: Int = 200,
        enableRegionOptimization: Bool = true,
        interactionModes: MapInteractionModes = [.pan, .zoom],
        initialRegion: MKCoordinateRegion? = nil
    ) {
        self.visitedCountryCodes = Set(visitedCountryCodes.map { $0.uppercased() })
        self.visitedColor = visitedColor
        self.unvisitedColor = unvisitedColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.maxPointsPerPolygon = maxPointsPerPolygon
        self.enableRegionOptimization = enableRegionOptimization
        self.interactionModes = interactionModes
        
        // Région par défaut : Europe
        let region = initialRegion ?? MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.858370, longitude: 2.294481),
            latitudinalMeters: 8000000,
            longitudinalMeters: 8000000
        )
        self.initialRegion = region
        self._position = State(initialValue: .region(region))
    }
    
    /// Initialisation avec noms de pays
    public init(
        visitedCountryNames: Set<String>,
        visitedColor: Color = .blue,
        unvisitedColor: Color = .gray,
        strokeColor: Color = .white,
        strokeWidth: CGFloat = 0.5,
        maxPointsPerPolygon: Int = 200,
        enableRegionOptimization: Bool = true,
        interactionModes: MapInteractionModes = [.pan, .zoom],
        initialRegion: MKCoordinateRegion? = nil
    ) {
        let loader = CountryDataLoader.shared
        let codes = visitedCountryNames.compactMap { name -> String? in
            loader.getCountry(byName: name)?.id
        }
        
        self.visitedCountryCodes = Set(codes.map { $0.uppercased() })
        self.visitedColor = visitedColor
        self.unvisitedColor = unvisitedColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.maxPointsPerPolygon = maxPointsPerPolygon
        self.enableRegionOptimization = enableRegionOptimization
        self.interactionModes = interactionModes
        
        // Région par défaut : Europe
        let region = initialRegion ?? MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.858370, longitude: 2.294481),
            latitudinalMeters: 8000000,
            longitudinalMeters: 8000000
        )
        self.initialRegion = region
        self._position = State(initialValue: .region(region))
    }
    
    /// Initialisation sans pays visités (toute la carte grise)
    public init(
        visitedColor: Color = .blue,
        unvisitedColor: Color = .gray,
        strokeColor: Color = .white,
        strokeWidth: CGFloat = 0.5,
        maxPointsPerPolygon: Int = 200,
        enableRegionOptimization: Bool = true,
        interactionModes: MapInteractionModes = [.pan],
        initialRegion: MKCoordinateRegion? = nil
    ) {
        self.visitedCountryCodes = []
        self.visitedColor = visitedColor
        self.unvisitedColor = unvisitedColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.maxPointsPerPolygon = maxPointsPerPolygon
        self.enableRegionOptimization = enableRegionOptimization
        self.interactionModes = interactionModes
        
        // Région par défaut : Europe
        let region = initialRegion ?? MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.858370, longitude: 2.294481),
            latitudinalMeters: 8000000,
            longitudinalMeters: 8000000
        )
        self.initialRegion = region
        self._position = State(initialValue: .region(region))
    }
    
    // MARK: - Body
    
    public var body: some View {
        Map(position: $position, interactionModes: interactionModes) {
            ForEach(visibleCountries) { country in
                let isVisited = visitedCountryCodes.contains(country.id.uppercased())
                
                ForEach(country.polygons.indices, id: \.self) { index in
                    let coordinates = country.polygons[index]
                    let simplifiedCoords = simplifyPolygon(coordinates, maxPoints: maxPointsPerPolygon)
                    
                    MapPolygon(coordinates: simplifiedCoords)
                        .foregroundStyle(isVisited ? visitedColor : unvisitedColor)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            if enableRegionOptimization {
                currentRegion = context.region
                updateVisibleCountries()
            }
        }
        .task {
            await loadCountries()
        }
    }
    
    // MARK: - Méthodes privées
    
    private func loadCountries() async {
        let countries = CountryDataLoader.shared.getAllCountries()
        allCountries = countries
        updateVisibleCountries()
        
//        #if DEBUG
//        printOptimizationStats(countries)
//        #endif
    }
    
    private func updateVisibleCountries() {
        if !enableRegionOptimization {
            // Mode sans optimisation : afficher tous les pays
            visibleCountries = allCountries
            return
        }
        
        guard let region = currentRegion else {
            // Vue initiale : tous les pays
            visibleCountries = allCountries
            return
        }
        
        // ✅ Filtrer par polygon visible dans la région
        visibleCountries = allCountries.compactMap { country in
            let visiblePolygonIndices = country.getVisiblePolygonIndices(in: region)
            
            if visiblePolygonIndices.isEmpty {
                return nil
            }
            
            return country.withFilteredPolygons(visiblePolygonIndices)
        }
    }
    
    /// Simplifie un polygon en gardant maximum N points
    private func simplifyPolygon(_ coords: [CLLocationCoordinate2D], maxPoints: Int) -> [CLLocationCoordinate2D] {
        guard coords.count > maxPoints else { return coords }
        
        let step = coords.count / maxPoints
        var result: [CLLocationCoordinate2D] = []
        
        for i in stride(from: 0, to: coords.count, by: step) {
            result.append(coords[i])
        }
        
        // Toujours inclure le dernier point pour fermer le polygon
        if let last = coords.last, let resultLast = result.last {
            if last.latitude != resultLast.latitude || last.longitude != resultLast.longitude {
                result.append(last)
            }
        }
        
        return result
    }
    
    /// Stats d'optimisation (DEBUG uniquement)
    private func printOptimizationStats(_ countries: [Country]) {
        let totalPolygons = countries.reduce(0) { $0 + $1.polygons.count }
        let totalPoints = countries.reduce(0) { total, country in
            total + country.polygons.reduce(0) { $0 + $1.count }
        }
        let estimatedOptimized = min(totalPoints, totalPolygons * maxPointsPerPolygon)
        let reduction = Int((1.0 - Double(estimatedOptimized) / Double(totalPoints)) * 100)
        
        print("📊 WorldMapView - Configuration:")
        print("   - Optimisation région: \(enableRegionOptimization ? "✅" : "❌")")
        print("   - Max points/polygon: \(maxPointsPerPolygon)")
        print("   - Interactions: \(interactionModes)")
        print("")
        print("📈 Statistiques:")
        print("   - Pays: \(countries.count)")
        print("   - Polygons: \(totalPolygons)")
        print("   - Points avant: \(totalPoints)")
        print("   - Points après: ~\(estimatedOptimized)")
        print("   - Réduction: \(reduction)%")
        
        let top5 = countries
            .map { country -> (String, Int, Int) in
                let points = country.polygons.reduce(0) { $0 + $1.count }
                return (country.name, country.polygons.count, points)
            }
            .sorted { $0.2 > $1.2 }
            .prefix(5)
        
        print("")
        print("🔝 Top 5 pays complexes:")
        for (index, stat) in top5.enumerated() {
            print("   \(index + 1). \(stat.0): \(stat.1) polygons, \(stat.2) points")
        }
    }
}

// MARK: - Régions prédéfinies

extension MKCoordinateRegion {
    /// Europe (région par défaut)
    public static let europe = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.858370, longitude: 2.294481),
        latitudinalMeters: 8000000,
        longitudinalMeters: 8000000
    )
    
    /// Monde entier
    public static let world = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        latitudinalMeters: 40000000,
        longitudinalMeters: 40000000
    )
    
    /// Amérique du Nord
    public static let northAmerica = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40, longitude: -100),
        latitudinalMeters: 8000000,
        longitudinalMeters: 8000000
    )
    
    /// Amérique du Sud
    public static let southAmerica = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -15, longitude: -60),
        latitudinalMeters: 8000000,
        longitudinalMeters: 8000000
    )
    
    /// Asie
    public static let asia = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30, longitude: 100),
        latitudinalMeters: 8000000,
        longitudinalMeters: 8000000
    )
    
    /// Afrique
    public static let africa = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 20),
        latitudinalMeters: 8000000,
        longitudinalMeters: 8000000
    )
    
    /// Océanie
    public static let oceania = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -25, longitude: 135),
        latitudinalMeters: 6000000,
        longitudinalMeters: 6000000
    )
    
    /// France métropolitaine
    public static let france = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.603354, longitude: 2.888334),
        latitudinalMeters: 1200000,
        longitudinalMeters: 1200000
    )
    
    /// États-Unis
    public static let usa = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        latitudinalMeters: 5000000,
        longitudinalMeters: 5000000
    )
}


// MARK: - Previews

#Preview("Configuration par défaut") {
    WorldMapView(
        visitedCountryCodes: ["FR", "US", "ES"]
    )
    .frame(height: 400)
}

#Preview("Monde entier") {
    WorldMapView(
        visitedCountryCodes: ["FR", "US", "CN", "AU", "BR"],
        initialRegion: .world
    )
    .frame(height: 400)
}

#Preview("Amérique du Nord") {
    WorldMapView(
        visitedCountryCodes: ["US", "CA", "MX"],
        initialRegion: .northAmerica
    )
    .frame(height: 400)
}

#Preview("Asie") {
    WorldMapView(
        visitedCountryCodes: ["JP", "CN", "IN", "TH"],
        initialRegion: .asia
    )
    .frame(height: 400)
}

#Preview("France zoom") {
    WorldMapView(
        visitedCountryCodes: ["FR"],
        visitedColor: .blue,
        initialRegion: .france
    )
    .frame(height: 400)
}

#Preview("Sans optimisation région") {
    WorldMapView(
        visitedCountryCodes: ["FR", "DE", "IT"],
        enableRegionOptimization: false
    )
    .frame(height: 400)
}

#Preview("Performance maximale") {
    WorldMapView(
        visitedCountryCodes: ["JP", "PH", "ID"],
        maxPointsPerPolygon: 100,
        enableRegionOptimization: true,
        initialRegion: .asia
    )
    .frame(height: 400)
}

#Preview("Carte statique") {
    WorldMapView(
        visitedCountryCodes: ["FR", "US", "JP"],
        interactionModes: [],
        initialRegion: .world
    )
    .frame(height: 400)
}
