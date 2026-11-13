import Foundation

/// Imperial (inch, SFM, IPM) or metric (mm, m/min, mm/min). Kept as an explicit choice rather than
/// guessing from locale, because a machinist switching units by mistake is the one error this app
/// must never cause silently.
public enum UnitSystem: String, CaseIterable, Sendable {
    case imperial
    case metric
}
