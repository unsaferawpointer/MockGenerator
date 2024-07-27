//
//  FunctionSignatureSyntax+.swift
//
//
//  Created by Anton Cherkasov on 10.05.2024.
//

import SwiftSyntax

extension FunctionParameterSyntax {

	var usedName: TokenSyntax {
		guard let secondName else {
			if firstName.tokenKind != .wildcard {
				return firstName
			} else {
				return .identifier("value")
			}
		}

		return secondName
	}
}
