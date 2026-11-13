import Foundation
import ChiploadCore

/// Drives one calculator screen. Kept framework-free (no SwiftUI import) so the actual math stays
/// testable the same way ChiploadCore's own tests run, without needing a simulator.
@Observable
final class CalculatorModel {
    enum OperationKind: String, CaseIterable, Identifiable {
        case milling = "Milling"
        case turning = "Turning"
        case drilling = "Drilling"
        var id: String { rawValue }
    }

    var units: UnitSystem = .imperial
    var operationKind: OperationKind = .milling
    var toolMaterial: ToolMaterial = .carbide
    var selectedMaterial: String = MaterialReference.library.first!.name

    var diameter: Double = 0.5
    var flutes: Int = 4
    var chipLoad: Double = 0.004 // inches/tooth or mm/tooth, or feed/rev for turning & drilling

    /// The operation's own SFM/Vc range for the selected material and tool, shown as a hint, not a
    /// locked-in value: the user can always dial in their own number.
    var suggestedSpeedRange: ClosedRange<Double>? {
        MaterialReference.sfmRange(for: selectedMaterial, toolMaterial: toolMaterial)
    }

    var cuttingSpeed: Double = 400 // SFM or m/min, whichever `units` is

    private var operation: Operation {
        switch operationKind {
        case .milling: return .milling(flutes: flutes)
        case .turning: return .turning
        case .drilling: return .drilling
        }
    }

    var rpm: Double {
        SpeedsAndFeeds.spindleSpeed(cuttingSpeed: cuttingSpeed, diameter: diameter, units: units)
    }

    var feedRate: Double {
        SpeedsAndFeeds.feedRate(rpm: rpm, operation: operation, feedPerTooth: chipLoad)
    }

    var speedUnitLabel: String { units == .imperial ? "SFM" : "m/min" }
    var lengthUnitLabel: String { units == .imperial ? "in" : "mm" }
    var feedUnitLabel: String { units == .imperial ? "IPM" : "mm/min" }
    var chipLoadUnitLabel: String {
        switch operationKind {
        case .milling: return units == .imperial ? "in/tooth" : "mm/tooth"
        case .turning, .drilling: return units == .imperial ? "in/rev" : "mm/rev"
        }
    }

    func applySuggestedSpeed() {
        guard let range = suggestedSpeedRange else { return }
        cuttingSpeed = (range.lowerBound + range.upperBound) / 2
    }
}
