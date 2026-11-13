import XCTest
@testable import ChiploadCore

final class SpeedsAndFeedsTests: XCTestCase {
    // 1" HSS end mill, mild steel, SFM 100: RPM = 100 * 12 / (pi * 1) = 1200/pi = 381.97
    func testImperialSpindleSpeed() {
        let rpm = SpeedsAndFeeds.spindleSpeed(cuttingSpeed: 100, diameter: 1.0, units: .imperial)
        XCTAssertEqual(rpm, 381.97, accuracy: 0.1)
    }

    // 10mm carbide end mill, Vc 30 m/min: RPM = 30*1000/(pi*10) = 954.93
    func testMetricSpindleSpeed() {
        let rpm = SpeedsAndFeeds.spindleSpeed(cuttingSpeed: 30, diameter: 10, units: .metric)
        XCTAssertEqual(rpm, 954.93, accuracy: 0.1)
    }

    // cuttingSpeed is the exact inverse of spindleSpeed.
    func testCuttingSpeedIsInverseOfSpindleSpeed() {
        let rpm = SpeedsAndFeeds.spindleSpeed(cuttingSpeed: 237.0, diameter: 0.5, units: .imperial)
        let back = SpeedsAndFeeds.cuttingSpeed(rpm: rpm, diameter: 0.5, units: .imperial)
        XCTAssertEqual(back, 237.0, accuracy: 1e-6)

        let rpmM = SpeedsAndFeeds.spindleSpeed(cuttingSpeed: 80.0, diameter: 12, units: .metric)
        let backM = SpeedsAndFeeds.cuttingSpeed(rpm: rpmM, diameter: 12, units: .metric)
        XCTAssertEqual(backM, 80.0, accuracy: 1e-6)
    }

    // 382 RPM, 2-flute, 0.004"/tooth chip load: feed = 382 * 2 * 0.004 = 3.056 IPM
    func testMillingFeedRate() {
        let feed = SpeedsAndFeeds.feedRate(rpm: 382, operation: .milling(flutes: 2), feedPerTooth: 0.004)
        XCTAssertEqual(feed, 3.056, accuracy: 0.001)
    }

    // 955 RPM, 4-flute, 0.05mm/tooth: feed = 955 * 4 * 0.05 = 191 mm/min
    func testMillingFeedRateMetric() {
        let feed = SpeedsAndFeeds.feedRate(rpm: 955, operation: .milling(flutes: 4), feedPerTooth: 0.05)
        XCTAssertEqual(feed, 191.0, accuracy: 0.01)
    }

    // Turning: 500 RPM, 0.008 ipr: feed = 4.0 IPM
    func testTurningFeedRate() {
        let feed = SpeedsAndFeeds.feedRate(rpm: 500, operation: .turning, feedPerTooth: 0.008)
        XCTAssertEqual(feed, 4.0, accuracy: 1e-9)
    }

    // Drilling behaves like turning: one feed-per-rev number, no flute multiplier.
    func testDrillingFeedRate() {
        let feed = SpeedsAndFeeds.feedRate(rpm: 800, operation: .drilling, feedPerTooth: 0.003)
        XCTAssertEqual(feed, 2.4, accuracy: 1e-9)
    }

    // feedPerTooth is the exact inverse of feedRate for milling.
    func testFeedPerToothIsInverseForMilling() {
        let feed = SpeedsAndFeeds.feedRate(rpm: 1200, operation: .milling(flutes: 3), feedPerTooth: 0.005)
        let back = SpeedsAndFeeds.feedPerTooth(feedRate: feed, rpm: 1200, operation: .milling(flutes: 3))
        XCTAssertEqual(back, 0.005, accuracy: 1e-9)
    }

    func testFeedPerToothIsInverseForTurning() {
        let feed = SpeedsAndFeeds.feedRate(rpm: 650, operation: .turning, feedPerTooth: 0.007)
        let back = SpeedsAndFeeds.feedPerTooth(feedRate: feed, rpm: 650, operation: .turning)
        XCTAssertEqual(back, 0.007, accuracy: 1e-9)
    }

    func testZeroDiameterDoesNotCrashOrDivideByZero() {
        let rpm = SpeedsAndFeeds.spindleSpeed(cuttingSpeed: 100, diameter: 0, units: .imperial)
        XCTAssertEqual(rpm, 0)
    }

    func testZeroRPMFeedPerToothDoesNotCrash() {
        let v = SpeedsAndFeeds.feedPerTooth(feedRate: 10, rpm: 0, operation: .turning)
        XCTAssertEqual(v, 0)
    }

    func testZeroFlutesDoesNotCrash() {
        let feed = SpeedsAndFeeds.feedRate(rpm: 1000, operation: .milling(flutes: 0), feedPerTooth: 0.005)
        XCTAssertEqual(feed, 0)
        let back = SpeedsAndFeeds.feedPerTooth(feedRate: 10, rpm: 1000, operation: .milling(flutes: 0))
        XCTAssertEqual(back, 0)
    }

    // Milling MRR: 10 IPM feed, 0.5" width, 0.1" depth = 0.5 in^3/min
    func testMillingRemovalRateImperial() {
        let mrr = SpeedsAndFeeds.millingRemovalRate(feedRate: 10, widthOfCut: 0.5, depthOfCut: 0.1, units: .imperial)
        XCTAssertEqual(mrr, 0.5, accuracy: 1e-9)
    }

    func testMillingRemovalRateMetric() {
        // 200 mm/min feed, 10mm width, 2mm depth = 4000 mm^3/min = 4 cm^3/min
        let mrr = SpeedsAndFeeds.millingRemovalRate(feedRate: 200, widthOfCut: 10, depthOfCut: 2, units: .metric)
        XCTAssertEqual(mrr, 4.0, accuracy: 1e-9)
    }
}

final class MaterialReferenceTests: XCTestCase {
    func testLibraryHasNoOverlappingNonsenseRanges() {
        for m in MaterialReference.library {
            XCTAssertLessThan(m.sfmRangeHSS.lowerBound, m.sfmRangeHSS.upperBound, m.name)
            XCTAssertLessThan(m.sfmRangeCarbide.lowerBound, m.sfmRangeCarbide.upperBound, m.name)
            XCTAssertLessThan(m.chipLoadRangeInches.lowerBound, m.chipLoadRangeInches.upperBound, m.name)
            // carbide reasonably allows higher speed than HSS for the same material
            XCTAssertGreaterThan(m.sfmRangeCarbide.lowerBound, m.sfmRangeHSS.lowerBound, m.name)
        }
    }

    func testLookupByName() {
        let r = MaterialReference.sfmRange(for: "Aluminum (6061)", toolMaterial: .carbide)
        XCTAssertEqual(r, 600...1200)
    }

    func testLookupMissingNameReturnsNil() {
        XCTAssertNil(MaterialReference.sfmRange(for: "Unobtainium", toolMaterial: .carbide))
    }
}
