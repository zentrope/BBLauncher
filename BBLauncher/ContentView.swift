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

    var body: some View {
		VStack {
			Button {
				
				store.addProject()
			} label: {
				Label("Add Project", systemImage: "plus")
			}
			Divider()
			ForEach(store.bookmarks.sorted(using: KeyPathComparator(\.name)), id: \.id) { bookmark in
				Button {
					store.open(bookmark)
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
			Button(role: .destructive) {
				NSApp.terminate(nil)
			} label: {
				Label("Quit BBLauncher", systemImage: "xmark.rectangle")
			}
		}
    }
}
