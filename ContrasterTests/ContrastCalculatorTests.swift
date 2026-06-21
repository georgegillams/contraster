//
//  ContrastCalculatorTests.swift
//  ContrasterTests
//

import SwiftUI
import XCTest
@testable import Contraster

final class ContrastCalculatorTests: XCTestCase {
    func testBlackOnWhiteContrastRatio() {
        let ratio = ContrastCalculator.calculateContrastRatio(color1: .black, color2: .white)
        XCTAssertEqual(ratio, 21.0, accuracy: 0.01)
    }

    func testIdenticalColorsHaveMinimumContrast() {
        let gray = Color(white: 0.5)
        let ratio = ContrastCalculator.calculateContrastRatio(color1: gray, color2: gray)
        XCTAssertEqual(ratio, 1.0, accuracy: 0.01)
    }

    func testLargeTextAACompliance() {
        let result = ContrastCalculator.compliance(for: 4.0)
        XCTAssertEqual(result.complianceLevelLgText, .passAA)
        XCTAssertEqual(result.complianceLevelSmText, .fail)
        XCTAssertEqual(result.contrastRatioLabel, "4.0:1")
    }

    func testSmallTextAAACompliance() {
        let result = ContrastCalculator.compliance(for: 7.5)
        XCTAssertEqual(result.complianceLevelSmText, .passAAA)
        XCTAssertEqual(result.complianceLevelLgText, .passAAA)
    }

    func testPendingCompliancePlaceholder() {
        let result = ContrastCalculator.pendingCompliance()
        XCTAssertEqual(result.complianceLevelLgText, .pending)
        XCTAssertEqual(result.complianceLevelSmText, .pending)
        XCTAssertEqual(result.complianceLevelGraphical, .pending)
    }

    func testAccessibleForegroundFindsHighContrastColor() {
        let background = Color(red: 0.2, green: 0.2, blue: 0.8)
        let foreground = ContrastCalculator.calculateAccessibleForegroundColour(
            forBackground: background,
            closestTo: background
        )
        let ratio = ContrastCalculator.calculateContrastRatio(color1: background, color2: foreground)
        XCTAssertGreaterThanOrEqual(ratio, 6.0)
    }
}
