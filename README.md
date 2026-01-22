# TravelMapKit

TravelMapKit est un **Swift Package réutilisable** pour afficher une **carte du monde interactive en SwiftUI**, avec les pays visités colorés et les pays non visités en gris. Idéal pour les applications de voyage ou les profils d’utilisateurs.

---

##  Fonctionnalités

- Affiche tous les pays du monde à partir d’un GeoJSON.
- Met en évidence les pays visités avec une couleur.
- Les pays non visités apparaissent en gris.
- Utilise SwiftUI `Map` et `MapPolygon`.
- Compatible iOS 17+.

---

## Installation

### Avec Xcode

1. Dans votre projet, allez dans **File → Add Packages…**
2. Colle l'url du repository git
3. Importez le package dans votre code :

```swift
import TravelMapKit
```

`WorldMapView(
    visitedCountries: ["FR", "USA"],
    visitedColor: .blue,
    unvisitedColor: .gray
)` 



## Licence
MIT License
Copyright (c) 2026 Guillaume Genest
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.
