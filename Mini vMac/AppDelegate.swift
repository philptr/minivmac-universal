//
//  AppDelegate.swift
//  Mini vMac
//
//  Created by Phil Zakharchenko on 1/31/25.
//

import AppKit

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let arguments = AppArguments.parseOrExit()
        
        guard let frameworksURL = Bundle.main.privateFrameworksURL,
              let urls = Bundle.urls(forResourcesWithExtension: nil, subdirectory: nil, in: frameworksURL) else {
            fatalError("Could not find the private frameworks URL for the main bundle.")
        }
        
        let bundles = urls
            .filter { $0.deletingPathExtension().lastPathComponent == arguments.emulatorName }
            .compactMap { Bundle(url: $0) }
        
        guard let bundle = bundles.first else {
            fatalError("Could not load an emulator bundle for name '\(arguments.emulatorName)'.")
        }
        
        try! bundle.loadAndReturnError()
        
        if let displayName = bundle.infoDictionary?["CFBundleDisplayName"] as? String {
            print("Loaded bundle: \(displayName).")
        }

        let principalClass = bundle.principalClass as! EmulatorVariation.Type
        let emulator = principalClass.init(romAtPath: arguments.romPath)
        
        RunLoop.main.perform {
            for diskPath in arguments.disks {
                emulator.insertDisk(atPath: diskPath)
            }
        }

        emulator.start()
        
        bundle.unload()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

