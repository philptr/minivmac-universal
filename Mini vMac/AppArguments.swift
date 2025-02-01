//
//  AppArguments.swift
//  Mini vMac
//
//  Created by Phil Zakharchenko on 2/1/25.
//

import ArgumentParser

struct AppArguments: ParsableCommand {
    @Option(name: .customLong("emulator", withSingleDash: true))
    var emulatorName: String
    
    @Option(name: .customLong("rom", withSingleDash: true))
    var romPath: String
    
    @Option(name: .customLong("disks", withSingleDash: true))
    var disks: [String]
}
