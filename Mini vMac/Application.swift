//
//  Application.swift
//  Mini vMac
//
//  Created by Phil Zakharchenko on 2/1/25.
//

import AppKit

final class Application: NSApplication {
    let strongDelegate = AppDelegate()
    
    override init() {
        super.init()
        self.delegate = strongDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
