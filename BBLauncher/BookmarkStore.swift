//
//  BookmarkStore.swift
//  BBLauncher
//
//  Created by Keith Irwin on 12/31/25.
//

import SwiftUI

@Observable
final class BookmarkStore {


	var bookmarks: [Bookmark] = []
	var error: Error?

	private let storageFileName = "bookmarks.json"
	private let bbedit = URL(string: "file:///Applications/BBEdit.app")!
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
		if result == .OK {
			guard let url = panel.url else { return }

			NSWorkspace.shared.open([url], withApplicationAt: bbedit, configuration: self.config) { app, error in
				if let error {
					print("❌ \(error)")
					return
				}

				do {
					try self.add(url: url)
				} catch (let error) {
					print("❌ \(error)")
				}
			}
		} else {
			print("❌ didn't work or cancelled")
		}
	}

	func open(_ bookmark: Bookmark) {
		var isStale: Bool = false
		guard let data = Data(base64Encoded: bookmark.code),
				let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], bookmarkDataIsStale: &isStale) else {
			print("❌ Unable to open bookmark. TODO: create an error to push up.")
			return
		}

		let result = url.startAccessingSecurityScopedResource()
		if !result {
			print("❌ Unable to start security scope, TODO: create an error to push up.")
			return
		}

		let workspace = NSWorkspace.shared
		let files = [url]
		workspace.open(files, withApplicationAt: self.bbedit, configuration: self.config) { app, error in
			if let error {
				print("❌ \(error)")
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
			print("❌ Unable to find app support directory.")
			return
		}

		let file = appSupport.appendingPathComponent(storageFileName)
		make(file: file)

		do {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			let data = try encoder.encode(bookmarks)
			try data.write(to: file)
			print("✅ Saved data to \(file)")
		} catch (let error) {
			print("❌ Unable to save file: '\(file)', '\(error)'.")
		}
	}

	private func load() {
		guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
			print("❌ Unable to find app support directory.")
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
			print("✅ Loaded data from \(file)")
		} catch (let error) {
			fatalError("❌ Unable to save file: '\(file)', '\(error)'.")
		}
	}

	private func make(file: URL) {
		if FileManager.default.fileExists(atPath: file.path) {
			return
		}

		print("❌ File does not exist: \(file.absoluteString), creating...")
		do {
			let data = "[]".data(using: .utf8)!
			try data.write(to: file)
		} catch {
			fatalError("❌ Unable to write initial file: \(file.absoluteString)")
		}
	}
}
