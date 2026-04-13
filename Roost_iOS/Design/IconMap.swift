import Foundation

/// Avatar icons — raw values match the `id` strings stored in Supabase (`home_members.avatar_icon`).
/// Must stay in sync with AVATAR_ICON_OPTIONS in Roost Mac/MemberAvatar.tsx.
enum LucideIcon: String, CaseIterable, Codable {
    case star      = "Star"
    case heart     = "Heart"
    case flame     = "Flame"
    case zap       = "Zap"
    case sun       = "Sun"
    case moon      = "Moon"
    case leaf      = "Leaf"
    case music     = "Music"
    case camera    = "Camera"
    case coffee    = "Coffee"
    case bike      = "Bike"
    case plane     = "Plane"
    case trophy    = "Trophy"
    case crown     = "Crown"
    case rocket    = "Rocket"
    case palette   = "Palette"
    case bookOpen  = "BookOpen"
    case compass   = "Compass"
    case mountain  = "Mountain"
    case globe     = "Globe"
    case smile     = "Smile"
    case gem       = "Gem"
    case pizza     = "Pizza"
    case gamepad2  = "Gamepad2"

    var sfSymbolName: String {
        switch self {
        case .star:     return "star"
        case .heart:    return "heart"
        case .flame:    return "flame"
        case .zap:      return "bolt"
        case .sun:      return "sun.max"
        case .moon:     return "moon"
        case .leaf:     return "leaf"
        case .music:    return "music.note"
        case .camera:   return "camera"
        case .coffee:   return "cup.and.saucer"
        case .bike:     return "bicycle"
        case .plane:    return "airplane"
        case .trophy:   return "trophy"
        case .crown:    return "crown"
        case .rocket:   return "rocket"
        case .palette:  return "paintpalette"
        case .bookOpen: return "book"
        case .compass:  return "safari"
        case .mountain: return "mountain.2"
        case .globe:    return "globe"
        case .smile:    return "face.smiling"
        case .gem:      return "diamond"
        case .pizza:    return "birthday.cake"
        case .gamepad2: return "gamecontroller"
        }
    }

    /// Resolves any stored icon string — current PascalCase avatar IDs, legacy lowercase iOS avatar
    /// names, Lucide room icon names, or raw SF Symbol strings — to an SF Symbol name.
    /// Returns nil only for truly unrecognised strings.
    static func sfSymbolName(for rawValue: String?) -> String? {
        guard let rawValue else { return nil }

        // 1. Current PascalCase avatar icon
        if let icon = Self(rawValue: rawValue) {
            return icon.sfSymbolName
        }

        // 2. Legacy lowercase avatar icons stored by older iOS builds
        switch rawValue {
        case "star":    return Self.star.sfSymbolName
        case "heart":   return Self.heart.sfSymbolName
        case "flame":   return Self.flame.sfSymbolName
        case "zap":     return Self.zap.sfSymbolName
        case "sun":     return Self.sun.sfSymbolName
        case "moon":    return Self.moon.sfSymbolName
        case "leaf":    return Self.leaf.sfSymbolName
        case "music":   return Self.music.sfSymbolName
        case "camera":  return Self.camera.sfSymbolName
        case "coffee":  return Self.coffee.sfSymbolName
        case "bike":    return Self.bike.sfSymbolName
        case "plane":   return Self.plane.sfSymbolName
        case "trophy":  return Self.trophy.sfSymbolName
        case "crown":   return Self.crown.sfSymbolName
        case "rocket":  return Self.rocket.sfSymbolName
        case "compass": return Self.compass.sfSymbolName
        case "palette": return Self.palette.sfSymbolName
        case "smile":   return Self.smile.sfSymbolName
        case "gem":     return Self.gem.sfSymbolName
        // Old iOS-only icons removed from picker but still in DB for some users
        case "user":    return "person"
        case "home":    return "house"
        case "cloud":   return "cloud"
        case "flower":  return "camera.macro"
        case "tree":    return "tree"
        case "bird":    return "bird"
        case "cat":     return "cat"
        case "dog":     return "dog"
        case "fish":    return "fish"
        case "bug":     return "ladybug"
        case "book":    return "book"
        case "anchor":  return "ferry"
        case "diamond": return "diamond"
        default: break
        }

        // 3. Lucide room / group icon names (from Mac rooms.ts)
        switch rawValue {
        case "Home":            return "house"
        case "ChefHat":         return "fork.knife"
        case "Sofa":            return "sofa"
        case "Bed":             return "bed.double"
        case "BedDouble":       return "bed.double"
        case "Bath":            return "shower.fill"
        case "ShowerHead":      return "shower.fill"
        case "Droplets":        return "drop"
        case "DoorOpen":        return "door.left.hand.open"
        case "UtensilsCrossed": return "fork.knife"
        case "Laptop":          return "laptopcomputer"
        case "Trees":           return "tree"
        case "Flower2":         return "camera.macro"
        case "Car":             return "car"
        case "Package":         return "archivebox"
        case "Archive":         return "archivebox"
        case "Shirt":           return "tshirt"
        case "Dumbbell":        return "figure.strengthtraining.traditional"
        case "Wrench":          return "wrench.and.screwdriver"
        case "Layers":          return "square.grid.2x2"
        case "Building2":       return "building.2"
        default: break
        }

        // 4. Anything else is treated as an already-valid SF Symbol (legacy iOS-created rooms)
        return rawValue
    }
}
