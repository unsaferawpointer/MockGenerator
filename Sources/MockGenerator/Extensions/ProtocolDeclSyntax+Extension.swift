//
//  ProtocolDeclSyntax+Extension.swift
//
//
//  Created by Anton Cherkasov on 05.05.2024.
//

import SwiftSyntax

extension ProtocolDeclSyntax {

	static var mockType: IdentifierTypeSyntax {
		let base = "self.name.text"
		return IdentifierTypeSyntax(name: .identifier("\(base)Mock"))
	}
}
