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
        
        // Find all framework URLs.
        guard let frameworksURL = Bundle.main.privateFrameworksURL,
              let urls = Bundle.urls(forResourcesWithExtension: nil, subdirectory: nil, in: frameworksURL) else {
            fatalError("Could not find the private frameworks URL for the main bundle.")
        }
        
        // Instantiate an emulator from the correct bundle.
        let emulator: EmulatorVariation?
        if let explicitEmulatorName = arguments.emulatorName {
            // The emulator name has been explicitly provided as a launch argument.
            // This will be the only bundle we consider.
            let candidateBundles = urls
                .filter { $0.deletingPathExtension().lastPathComponent == explicitEmulatorName }
                .compactMap { Bundle(url: $0) }
            
            guard let bundle = candidateBundles.first else {
                fatalError("Could not load an emulator bundle for an explicitly specified name '\(explicitEmulatorName)'.")
            }
            
            emulator = emulatorVariation(from: bundle, romPath: arguments.romPath)
        } else {
            // No emulator name has been provided.
            // Try each bundle and return the first non-nil value, which will correspond
            // to the instance that is capable of emulating the ROM.
            emulator = urls
                .compactMap { Bundle(url: $0) }
                .firstNonNil { bundle in
                    emulatorVariation(from: bundle, romPath: arguments.romPath)
                }
        }

        guard let emulator else {
            fatalError("Could not find emulator matching the requirements.")
        }
        
        RunLoop.main.perform {
            for diskPath in arguments.disks {
                emulator.insertDisk(atPath: diskPath)
            }
        }

        emulator.start()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    /// - Returns: The ``EmulatorVariation`` instance in the provided `Bundle` if
    /// it is capable of emulating the ROM at the specified path. Returns `nil`
    /// if the provided bundle cannot emulate the ROM.
    private func emulatorVariation(from bundle: Bundle, romPath: String) -> EmulatorVariation? {
        bundle.load()
        
        guard let principalClass = bundle.principalClass as? EmulatorVariation.Type,
              let emulator = principalClass.init(romAtPath: romPath) else {
            bundle.unload()
            return nil
        }
        
        return emulator
    }
}

extension Sequence {
    /// Returns the first non-`nil` result obtained from applying the given
    /// transformation to the elements of the sequence.
    ///
    ///     let strings = ["three", "3.14", "-5", "2"]
    ///     if let firstInt = strings.firstNonNil({ Int($0) }) {
    ///         print(firstInt)
    ///         // -5
    ///     }
    ///
    /// - Parameter transform: A closure that takes an element of the sequence as
    ///   its argument and returns an optional transformed value.
    /// - Returns: The first non-`nil` return value of the transformation, or
    ///   `nil` if no transformation is successful.
    ///
    /// - Complexity: O(*n*), where *n* is the number of elements at the start of
    ///   the sequence that result in `nil` when applying the transformation.
    @inlinable
    public func firstNonNil<Result>(
        _ transform: (Element) throws -> Result?
    ) rethrows -> Result? {
        for value in self {
            if let value = try transform(value) {
                return value
            }
        }
        return nil
    }
}
