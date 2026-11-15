//
//  StrategiesTest.swift
//  SwByeDPI
//
//  Created by developer on 20.04.2026.
//

import XCTest
@testable import SwByeDPI

final class StrategiesTests: XCTestCase {
    
    func testBuiltInStrategiesSyntax() async {
        await testStrategiesSetSyntax(TestConstants.builtInStrategies)
    }
    
    /*func testExperimentalStrategiesSyntax() async {
        await testStrategiesSetSyntax([RecentDPIeStrategies.strategiesList.strategies])
    }*/
    
    fileprivate func testStrategiesSetSyntax(_ strategies: [Set<SBDStrategy>]) async {
        var launchErrors: [SBDStrategy: Error] = [:]
        for strategySet in strategies {
            for strategy in strategySet {
                let config = strategy.generateConfig()
                guard let safeErr = await ByeDPI.start(args: config.args) else {
                    _ = ByeDPI.stop()
                    continue
                }
                launchErrors[strategy] = safeErr
            }
        }
        if (!launchErrors.isEmpty) {
            print(launchErrors)
        }
        XCTAssertEqual(launchErrors.count, 0, "byedpi launch fails detected. Possible invalid strategy (-ies) syntax or byedpi update")
    }
}
