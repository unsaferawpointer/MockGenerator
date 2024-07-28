//
//  Generator.swift
//
//
//  Created by Anton Cherkasov on 28.07.2024.
//

import Foundation
import SwiftParser
import SwiftSyntax

public protocol GeneratorProtocol {
	func generate(for source: String) throws -> String
}

public final class Generator {

	public init() { }
}

// MARK: - GeneratorProtocol
extension Generator: GeneratorProtocol {

	public func generate(for source: String) throws -> String {

		// MARK: - Start configuration

		let configuration = Configuration(
			action: .init(type: "Action", variable: "invocations"),
			stub: .init(type: "Stubs", variable: "stubs"),
			errors: .init(type: "Errors", variable: "errors")
		)

		var result = ""

		let syntax = Parser.parse(source: source)
		for statement in syntax.statements {
			guard let protocolDecl = statement.item.as(ProtocolDeclSyntax.self) else {
				print("IS NOT PROTOCOL")
				continue
			}
			let members = protocolDecl.memberBlock.members
			let functions = members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
			let data = DataFactory().makeData(from: functions)
			let structDecl = StubsFactory.makeStruct(for: functions, with: data, configuration: configuration.stub)

			var source = ""
			structDecl?.write(to: &source)
			print("SOURCE = \(source)")
			result.append(source)
		}
		return result
	}
}
