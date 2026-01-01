//
//  Bookmark.swift
//  BBLauncher
//
//  Created by Keith Irwin on 12/31/25.
//

struct Bookmark: Identifiable, Codable {
	var id: String { url }
	var name: String
	var url: String
	var code: String
}
