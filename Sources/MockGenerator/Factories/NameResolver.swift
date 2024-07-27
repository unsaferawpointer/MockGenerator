//
//  NameResolver.swift
//
//
//  Created by Anton Cherkasov on 10.05.2024.
//

import SwiftSyntax

protocol NameResolverProtocol {
	func resolve(_ name: TokenSyntax) -> TokenSyntax
}

final class NameResolver {
	// Avoid same enum case name
	private (set) var cache: Set<String> = []
}

// MARK: - NameResolverProtocol
extension NameResolver: NameResolverProtocol {

	func resolve(_ name: TokenSyntax) -> TokenSyntax {

		var version: Int = 1

		var current = name.text
		while cache.contains(current) {
			version += 1
			current = "\(name.text)V\(version)"
		}
		cache.insert(current)

		return .identifier(current)
	}
}
