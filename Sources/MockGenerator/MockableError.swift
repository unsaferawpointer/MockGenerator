//
//  MockableError.swift
//
//
//  Created by Anton Cherkasov on 05.05.2024.
//

import Foundation

enum MockableError: Error {
	case isNotAProtocol
	case protocolIsInherited
	case containsPrimaryAssociatedTypeClause
	case containsAssociatedTypeDeclSyntax
}

// MARK: - CustomStringConvertible
extension MockableError: CustomStringConvertible {

	var description: String {
		switch self {
		case .isNotAProtocol:
			"@MockGenerator can only be applied to protocols."
		case .protocolIsInherited:
			"@MockGenerator does not support inheritance"
		case .containsPrimaryAssociatedTypeClause:
			"@MockGenerator does not support primary associated type"
		case .containsAssociatedTypeDeclSyntax:
			"@MockGenerator does not support associated types"
		}
	}
}
