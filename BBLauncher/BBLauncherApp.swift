//
//  BBLauncherApp.swift
//  BBLauncher
//
//  Created by Keith Irwin on 12/31/25.
//

import SwiftUI

@main
struct BBLauncherApp: App {

	@State private var showPicker = false

    var body: some Scene {
		MenuBarExtra("BBLauncher", systemImage: "leaf") {
			ContentView()
		}
		.menuBarExtraStyle(.menu)
    }
}
