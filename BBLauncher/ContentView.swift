//
//  ContentView.swift
//  BBLauncher
//
//  Created by Keith Irwin on 12/31/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

	@State private var bookmarks = [Bookmark]()
	@State private var selectedBookmark: String?

	private var store = BookmarkStore()
	private var apps = ApplicationStore()

	@AppStorage("defaultApplicationId") var applicationId = ""

    var body: some View {
		VStack {
			ForEach(store.bookmarks.sorted(using: KeyPathComparator(\.name)), id: \.id) { bookmark in
				Button {
					open(bookmark)
				} label: {
					Label(bookmark.name, systemImage: "folder")
				}
				.modifierKeyAlternate([.option]) {
					Button(role: .destructive) {
						store.delete(bookmark)
					} label: {
						Label(bookmark.name, systemImage: "minus.circle.fill")
					}
				}
			}
			Divider()
			Button {
				store.addProject()
			} label: {
				Label("Project", systemImage: "plus")
			}
			Menu {
				ForEach(apps.applications, id: \.id) { app in
					Button {
						self.applicationId = app.id
					} label: {
						if app.id == applicationId {
							Label(app.name, systemImage: app.id == applicationId ? "checkmark" : "")
						} else {
							Text(app.name)
						}
					}
					.modifierKeyAlternate([.option]) {
						Button(role: .destructive) {
							apps.delete(app)
						} label: {
							Label(app.name, systemImage: "minus.circle.fill")
						}
						.help("Delete \(app.name)")
					}
				}
				Divider()
				Button {
					apps.findAndAddApplication()
				} label: {
					Label("Add", systemImage: "plus")
				}
			} label: {
				Label("Applications", systemImage: "app")
			}

			Divider()
			Button(role: .destructive) {
				NSApp.terminate(nil)
			} label: {
				Label("Quit BBLauncher", systemImage: "xmark.rectangle")
			}
		}
    }

	private func open(_ bookmark: Bookmark) {
		guard let app = apps.find(id: applicationId) else {
			return
		}
		store.open(bookmark, withApplication: app)

	}
}
