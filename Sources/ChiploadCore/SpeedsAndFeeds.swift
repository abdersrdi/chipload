import Foundation

/// The operation a calculation is for. Turning and drilling take a feed per revolution directly;
/// milling takes a feed per tooth multiplied by the flute count.
public enum CutOperation: Sendable {
    case milling(flutes: Int)
    case turning
    case drilling
}

public struct SpeedsAndFeeds {
    /// Spindle speed from a cutting speed and a tool (or, for turning, workpiece) diameter.
    ///
    /// Imperial: RPM = (SFM * 12) / (pi * D_inches)  -- the classic shop constant 3.82 is 12 / pi.
    /// Metric:   RPM = (Vc * 1000) / (pi * D_mm)
    ///
    /// Both are the same relation, unit speed = pi * diameter * RPM, solved for RPM; only the
    /// length-unit conversion differs (feet to inches, or meters to millimeters).
    public static func spindleSpeed(cuttingSpeed: Double, diameter: Double, units: UnitSystem) -> Double {
        guard diameter > 0 else { return 0 }
        switch units {
        case .imperial:
            return (cuttingSpeed * 12) / (.pi * diameter)
        case .metric:
            return (cuttingSpeed * 1000) / (.pi * diameter)
        }
    }

    /// The cutting speed (SFM or Vc) a given spindle RPM and diameter actually produce. The inverse
    /// of `spindleSpeed`, used when a machine's RPM is the fixed, known quantity.
    public static func cuttingSpeed(rpm: Double, diameter: Double, units: UnitSystem) -> Double {
        switch units {
        case .imperial:
            return (rpm * .pi * diameter) / 12
        case .metric:
            return (rpm * .pi * diameter) / 1000
        }
    }

    /// Table feed rate (IPM or mm/min).
    ///
    /// Milling: feed = RPM * flutes * chipLoad (feed per tooth).
    /// Turning / drilling: feed = RPM * feedPerRev.
    ///
    /// `feedPerTooth` is the chip load for milling, or the feed per revolution for turning and
    /// drilling; the name is kept generic because the arithmetic is identical once flutes is fixed
    /// at 1 for a single-point or single-flute operation.
    public static func feedRate(rpm: Double, operation: CutOperation, feedPerTooth: Double) -> Double {
        switch operation {
        case .milling(let flutes):
            return rpm * Double(max(flutes, 0)) * feedPerTooth
        case .turning, .drilling:
            return rpm * feedPerTooth
        }
    }

    /// The chip load (or feed per rev) a desired feed rate and RPM imply. The inverse of
    /// `feedRate`, for "I want this table speed, what chip load do I dial in?".
    public static func feedPerTooth(feedRate: Double, rpm: Double, operation: CutOperation) -> Double {
        guard rpm > 0 else { return 0 }
        switch operation {
        case .milling(let flutes):
            guard flutes > 0 else { return 0 }
            return feedRate / (rpm * Double(flutes))
        case .turning, .drilling:
            return feedRate / rpm
        }
    }

    /// Material removal rate.
    ///
    /// Milling (imperial, in^3/min; metric, cm^3/min with mm inputs /1000):
    ///   MRR = feedRate * widthOfCut * depthOfCut
    /// Turning:
    ///   MRR = cuttingSpeed(linear, length/min) * feedPerRev * depthOfCut
    ///   which this overload takes as feedRate (already RPM * feedPerRev) * depthOfCut, scaled by
    ///   pi * diameter being folded into feedRate's RPM term -- callers pass the turning feed rate
    ///   (length/min) and the radial depth of cut.
    public static func millingRemovalRate(feedRate: Double, widthOfCut: Double, depthOfCut: Double, units: UnitSystem) -> Double {
        let raw = feedRate * widthOfCut * depthOfCut
        switch units {
        case .imperial: return raw          // in^3/min
        case .metric: return raw / 1000      // mm^3/min -> cm^3/min
        }
    }
}
