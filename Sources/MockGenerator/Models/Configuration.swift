//
//  Configuration.swift
//
//
//  Created by Anton Cherkasov on 12.05.2024.
//

import SwiftSyntax

struct Configuration {

	private (set) var action: Action

	private (set) var stub: Stub

	private (set) var errors: Errors

	init(action: Action, stub: Stub, errors: Errors) {
		self.action = action
		self.stub = stub
		self.errors = errors
	}
}

extension Configuration {

	struct Action {
		let type: String
		let variable: String
	}

	struct Stub {
		let type: String
		let variable: String
	}

	struct Errors {
		let type: String
		let variable: String
	}
}

// MARK: - Computed properties for Stub
extension Configuration.Stub {

	var token: TokenSyntax {
		return .identifier(type)
	}
}

// MARK: - Computed properties for Action
extension Configuration.Action {

	var token: TokenSyntax {
		return .identifier(type)
	}
}

// MARK: - Computed properties for Errors
extension Configuration.Errors {

	var token: TokenSyntax {
		return .identifier(type)
	}
}
