//
//  Application.swift
//  BBLauncher
//
//  Created by Keith Irwin on 1/2/26.
//

import Foundation

struct Application: Identifiable, Codable {
	var id: String
	var name: String
	var url: String

	init(name: String, url: String) {
		self.id = UUID().uuidString
		self.name = name
		self.url = url
	}

	init(url: URL) {
		self.id = UUID().uuidString
		self.name = url.pathComponents.last?.replacingOccurrences(of: ".app", with: "") ?? "Unknown"
		self.url = url.absoluteString
	}
}
