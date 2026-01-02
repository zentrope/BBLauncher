//
//  ApplicationStore.swift
//  BBLauncher
//
//  Created by Keith Irwin on 1/2/26.
//

import Cocoa
import OSLog
import UniformTypeIdentifiers

@Observable
final class ApplicationStore {

	var applications: [Application] = []
	var error: Error?

	private let log = Logger("ApplicationStore")
	private let storageFileName = "applications.json"

	init() {
		load()
	}

	func delete(_ application: Application) {
		applications.removeAll(where: { $0.id == application.id })
		save()
	}

	func find(id: String) -> Application? {
		applications.first(where: { $0.id == id })
	}

	func findAndAddApplication() {
		let panel = NSOpenPanel()
		panel.canChooseFiles = true
		panel.canChooseDirectories = false
		panel.allowsMultipleSelection = false
		panel.prompt = "Select"
		panel.allowedContentTypes = [.application]

		let result = panel.runModal()

		switch result {
			case .OK:
				guard let url = panel.url else { return }
				let app = Application(url: url)
				self.applications = ([app] + applications).sorted(using: KeyPathComparator(\.name))
				save()
			case .cancel:
				log.info("Cancelled application picker.")
			default:
				log.error("Did not select application")
		}
	}

	private func save() {
		guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
			log.error("Unable to find app support directory.")
			return
		}

		let file = appSupport.appendingPathComponent(storageFileName)
		make(file: file)

		do {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			let data = try encoder.encode(applications)
			try data.write(to: file)
			log.info("Saved applications to \(file)")
		} catch (let error) {
			log.error("Unable to save file: '\(file)', '\(error)'.")
			self.error = error
		}
	}

	private func load() {
		guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
			log.error("Unable to find app support directory.")
			return
		}

		let file = appSupport.appendingPathComponent(storageFileName)
		make(file: file)

		do {
			let data = try Data(contentsOf: file)
			let decoder = JSONDecoder()
			let results = try decoder.decode([Application].self, from: data)
			let sorted = results.sorted(using: KeyPathComparator(\.name))
			self.applications = sorted
			log.info("Loaded data from \(file)")
		} catch (let error) {
			log.error("Unable to save file: '\(file)', '\(error)'.")
			self.error = error
		}
	}

	private func make(file: URL) {
		if FileManager.default.fileExists(atPath: file.path) {
			return
		}

		log.error("File does not exist: \(file.absoluteString), creating...")
		do {
			let data = "[]".data(using: .utf8)!
			try data.write(to: file)
		} catch {
			fatalError("❌ Unable to write initial file: \(file.absoluteString)")
		}

	}
}
