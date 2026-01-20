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
2. Choisissez **Local…** et sélectionnez le dossier du package `TravelMapKit`.
3. Importez le package dans votre code :

```swift
import TravelMapKit
