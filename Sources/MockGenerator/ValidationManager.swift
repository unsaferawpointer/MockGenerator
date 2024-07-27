//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 09.06.2024.
//

import SwiftSyntax

protocol ValidationManagerProtocol {
	static func validate(decl: some DeclSyntaxProtocol) throws -> ProtocolDeclSyntax
}

final class ValidationManager { }

// MARK: - ValidationManagerProtocol
extension ValidationManager: ValidationManagerProtocol {

	static func validate(decl: some DeclSyntaxProtocol) throws -> ProtocolDeclSyntax {

		guard let declaration = decl.as(ProtocolDeclSyntax.self) else {
			throw MockableError.isNotAProtocol
		}

		guard declaration.inheritanceClause == nil else {
			throw MockableError.protocolIsInherited
		}

		guard declaration.primaryAssociatedTypeClause == nil else {
			throw MockableError.containsPrimaryAssociatedTypeClause
		}

		return declaration
	}
}
