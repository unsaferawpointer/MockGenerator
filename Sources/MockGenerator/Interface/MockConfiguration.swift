//
//  MockConfiguration.swift
//
//
//  Created by Anton Cherkasov on 12.05.2024.
//

public struct MockConfiguration {

	private(set) var action: Action

	private(set) var stub: Stub

	private(set) var errors: Errors

	var comments: Comments

	init(action: Action, stub: Stub, errors: Errors, comments: Comments) {
		self.action = action
		self.stub = stub
		self.errors = errors
		self.comments = comments
	}
}

// MARK: - Nested data structs
extension MockConfiguration {

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

	struct Comments {
		var nestedStructsExtension: String
	}
}
