import Foundation

/// A starting point, not a spec. Ranges are the kind of broad, widely-published shop-reference
/// numbers found in machining handbooks and tool catalogs, for an uncoated or commonly coated
/// carbide end mill in average conditions. Every screen that shows one of these must say so: real
/// values depend on the specific tool, coating, machine rigidity and coolant, and the tool
/// manufacturer's own chart always wins over this table.
public struct MaterialReference: Sendable {
    public let name: String
    /// Cutting speed range in SFM (imperial) / (m/min) is `sfmRange / 3.28`, kept as one imperial
    /// figure and converted, rather than two independently chosen numbers that could drift apart.
    public let sfmRangeHSS: ClosedRange<Double>
    public let sfmRangeCarbide: ClosedRange<Double>
    /// Chip load range in inches per tooth, for a roughly 3/8"-1/2" diameter carbide end mill; scale
    /// down for smaller tools and up for larger ones (the app does this; this table is the midsize
    /// reference point).
    public let chipLoadRangeInches: ClosedRange<Double>

    public static let library: [MaterialReference] = [
        MaterialReference(name: "Aluminum (6061)", sfmRangeHSS: 200...300, sfmRangeCarbide: 600...1200, chipLoadRangeInches: 0.003...0.008),
        MaterialReference(name: "Mild steel (1018)", sfmRangeHSS: 80...110, sfmRangeCarbide: 350...550, chipLoadRangeInches: 0.002...0.006),
        MaterialReference(name: "Alloy steel (4140)", sfmRangeHSS: 60...90, sfmRangeCarbide: 250...400, chipLoadRangeInches: 0.0015...0.005),
        MaterialReference(name: "Stainless (304/316)", sfmRangeHSS: 40...60, sfmRangeCarbide: 150...300, chipLoadRangeInches: 0.0015...0.004),
        MaterialReference(name: "Cast iron (gray)", sfmRangeHSS: 70...100, sfmRangeCarbide: 300...500, chipLoadRangeInches: 0.003...0.007),
        MaterialReference(name: "Brass (free-machining)", sfmRangeHSS: 150...250, sfmRangeCarbide: 500...900, chipLoadRangeInches: 0.003...0.008),
        MaterialReference(name: "Titanium (Ti-6Al-4V)", sfmRangeHSS: 20...35, sfmRangeCarbide: 100...180, chipLoadRangeInches: 0.001...0.0035),
        MaterialReference(name: "Plastics / Delrin", sfmRangeHSS: 300...500, sfmRangeCarbide: 500...1000, chipLoadRangeInches: 0.004...0.010)
    ]

    public static func sfmRange(for name: String, toolMaterial: ToolMaterial) -> ClosedRange<Double>? {
        guard let m = library.first(where: { $0.name == name }) else { return nil }
        return toolMaterial == .hss ? m.sfmRangeHSS : m.sfmRangeCarbide
    }
}

public enum ToolMaterial: String, CaseIterable, Sendable {
    case hss = "HSS"
    case carbide = "Carbide"
}
