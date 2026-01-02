//
//  BookmarkStore.swift
//  BBLauncher
//
//  Created by Keith Irwin on 12/31/25.
//

import Cocoa
import OSLog

fileprivate let log = Logger("BookmarkStore")

@Observable
final class BookmarkStore {

	var bookmarks: [Bookmark] = []
	var error: Error?

	private let storageFileName = "bookmarks.json"
	private let config = NSWorkspace.OpenConfiguration()

	init() {
		config.activates = true
		load()
	}

	func delete(_ bookmark: Bookmark) {
		bookmarks.removeAll(where: { $0.id == bookmark.id })
		save()
	}

	func addProject() {
		let panel = NSOpenPanel()
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		panel.allowsMultipleSelection = false
		panel.prompt = "Select"

		let result = panel.runModal()

		switch result {
			case .OK:
				guard let url = panel.url else { return }
				do {
					try self.add(url: url)
				} catch (let error) {
					log.error("\(error)")
					self.error = error
				}
			case .cancel:
				log.info("User cancelled project fetch.")
			default:
				log.warning("User did not fetch project: \(String(describing: result))")
		}
	}

	func open(_ bookmark: Bookmark, withApplication application: Application) {
		var isStale: Bool = false
		guard let data = Data(base64Encoded: bookmark.code),
				let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], bookmarkDataIsStale: &isStale) else {
			log.error("Unable to open bookmark. TODO: create an error to push up.")
			return
		}

		let result = url.startAccessingSecurityScopedResource()
		if !result {
			log.error("Unable to start security scope, TODO: create an error to push up.")
			return
		}

		let app = URL(string: application.url)!
		let workspace = NSWorkspace.shared
		let files = [url]
		workspace.open(files, withApplicationAt: app, configuration: self.config) { app, error in
			if let error {
				log.error("\(error)")
				self.error = error
			}
			url.stopAccessingSecurityScopedResource()
		}
	}

	private func add(url: URL) throws {
		let name = url.pathComponents.last ?? "Unknown"
		let path = url.absoluteString
		let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: [.isDirectoryKey])
		let code = data.base64EncodedString()

		let bookmark = Bookmark(name: name, url: path, code: code)
		delete(bookmark)
		bookmarks.append(bookmark)
		save()
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
			let data = try encoder.encode(bookmarks)
			try data.write(to: file)
			log.info("Saved data to \(file, privacy: .public)")
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
			let results = try decoder.decode([Bookmark].self, from: data)
			let sorted = results.sorted(using: KeyPathComparator(\.name))
			self.bookmarks = sorted
			log.info("Loaded data from \(file, privacy: .public)")
		} catch (let error) {
			log.error("Unable to save file: '\(file)', '\(error)'.")
			self.error = error
		}
	}

	private func make(file: URL) {
		if FileManager.default.fileExists(atPath: file.path) {
			return
		}

		log.info("File does not exist: \(file.absoluteString, privacy: .public), creating...")
		do {
			let data = "[]".data(using: .utf8)!
			try data.write(to: file)
		} catch {
			log.error("Unable to write initial file: \(file.absoluteString, privacy: .public)")
			self.error = error
		}
	}
}
