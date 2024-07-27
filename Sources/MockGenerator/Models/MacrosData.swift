//
//  MacrosData.swift
//
//
//  Created by Anton Cherkasov on 12.05.2024.
//

import SwiftSyntax

struct FunctionData {
	var name: TokenSyntax
	var isAsync: Bool = false
	var throwsError: Bool = false
	var parameters: [Parameter] = []
}

struct Parameter {
	var name: TokenSyntax
	var type: TypeSyntax
	var isLast: Bool
}

struct MacrosData {
	
	private (set) var map: [FunctionSignatureSyntax: Int]

	private (set) var functions: [FunctionData] = []

	// MARK: - Initialization

	init(map: [FunctionSignatureSyntax : Int], cases: [FunctionData]) {
		self.map = map
		self.functions = cases
	}
}

// MARK: - Subscripts
extension MacrosData {

	subscript(_ signature: FunctionSignatureSyntax) -> FunctionData {
		guard let index = map[signature] else {
			fatalError("Cant find function in map")
		}
		return functions[index]
	}
}
