//
//  Logger.swift
//  BBLauncher
//
//  Created by Keith Irwin on 1/2/26.
//

import OSLog

extension Logger {
	init(_ category: String) {
		self.init(subsystem: Bundle.main.bundleIdentifier!, category: category)
	}
}
