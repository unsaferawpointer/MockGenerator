//
//  Generator.swift
//
//
//  Created by Anton Cherkasov on 28.07.2024.
//

import Foundation
import SwiftParser
import SwiftSyntax
import SwiftBasicFormat

public final class Generator {

	public init() { }
}

// MARK: - MockGeneratorProtocol
extension Generator: MockGeneratorProtocol {

	public func generate(for source: String) throws -> String {

		// MARK: - Start configuration

		let configuration = MockConfiguration(
			action: .init(type: "Action", variable: "invocations"),
			stub: .init(type: "Stubs", variable: "stubs"),
			errors: .init(type: "Errors", variable: "errors"), 
			comments: .init(nestedStructsExtension: "// MARK: - Вложенные типы данных")
		)

		let syntax = Parser.parse(source: source)

		let protocolDecls = syntax.statements.compactMap {
			$0.item.as(ProtocolDeclSyntax.self)
		}

		guard let protocolDecl = protocolDecls.first else {
			return ""
		}

		var source = ""

		var formatted = try Generator.makeMock(declaration: protocolDecl, configuration: configuration)

		BasicFormat(indentationWidth: .tab)
			.rewrite(formatted)
			.write(to: &source)

		return source
	}
}

// MARK: - Helpers
private extension Generator {

	static func makeNestedStructs(protocolDecl: ProtocolDeclSyntax, configuration: MockConfiguration) -> ExtensionDeclSyntax {

		let type = IdentifierTypeSyntax(name: .identifier("\(protocolDecl.name.text)Mock"))

		let functions: [FunctionDeclSyntax] = protocolDecl.memberBlock.members
			.compactMap {
				$0.decl.as(FunctionDeclSyntax.self)
			}

		// TODO: - Add Dependency Injection
		let data = DataFactory().makeData(from: functions, mockName: "\(protocolDecl.name.text)Mock")

		var members = MemberBlockItemListSyntax([])

		if let stubsDecl = StubsFactory(configuration: configuration.stub).makeStruct(for: functions, with: data) {
			let member = MemberBlockItemSyntax(decl: stubsDecl)
			members.append(member)
		}

		if let errorsDecl = ErrorsFactory.makeStruct(for: functions, with: data, configuration: configuration.errors) {
			let member = MemberBlockItemSyntax(decl: errorsDecl)
			members.append(member)
		}

		let actionsDecl = ActionsFactory.makeStruct(from: data, with: configuration.action)
		members.append(MemberBlockItemSyntax(decl: actionsDecl))

		let memberBlock = MemberBlockSyntax(members: members)

		let leadingTrivia: Trivia = [.newlines(2), .lineComment(configuration.comments.nestedStructsExtension), .newlines(1)]

		let result = ExtensionDeclSyntax(
			leadingTrivia: leadingTrivia,
			extendedType: type,
			memberBlock: memberBlock
		)
		return result
	}

	static func makeMock(declaration: some DeclSyntaxProtocol, configuration: MockConfiguration) throws -> CodeBlockItemListSyntax {

		let protocolDeclaration = try ValidationManager.validate(decl: declaration)

		// MARK: - End configuration

		let protocolMembers = protocolDeclaration.memberBlock.members

		let functions: [FunctionDeclSyntax] = protocolMembers.compactMap { $0.decl.as(FunctionDeclSyntax.self) }

		let data = DataFactory().makeData(from: functions, mockName: protocolDeclaration.name.text)

		var members = MemberBlockItemListSyntax()

		let mockName: TokenSyntax = .identifier("\(protocolDeclaration.name.text)Mock")
		let mockType = IdentifierTypeSyntax(name: mockName)

		// MARK: - Actions support

		members.append(MemberBlockItemSyntax(decl: ActionsFactory.makeVariable(with: configuration.action)))

		// MARK: - Errors support

		if let _ = ErrorsFactory.makeStruct(for: functions, with: data, configuration: configuration.errors) {
			let variable = ErrorsFactory.makeVariable(with: configuration.errors)
			let variableMember = MemberBlockItemSyntax(decl: variable)
			members.append(variableMember)
		}

		// MARK: - Stubs support

		if let _ = StubsFactory(configuration: configuration.stub).makeStruct(for: functions, with: data) {

			let variable = StubsFactory(configuration: configuration.stub).makeVariable()
			let variableMember = MemberBlockItemSyntax(decl: variable)
			members.append(variableMember)
		}

		let memberBlock = MemberBlockSyntax(members: members)

		let mock = ClassDeclSyntax(
			modifiers: .init({
				[DeclModifierSyntax(name: .keyword(.final))]
			}()),
			name: mockName,
			memberBlock: memberBlock
		)

		let declarations: [DeclSyntaxProtocol] = [
			mock,
			makeNestedStructs(protocolDecl: protocolDeclaration, configuration: configuration),
			ImplementationFactory(configuration: configuration).makeImplementation(protocolDecl: protocolDeclaration)
		]

		return CodeBlockItemListSyntax(
			declarations
				.map { DeclSyntax($0) }
				.map { CodeBlockItemSyntax(item: .decl($0)) }
		)
	}

	static func makeInheritanceClause(_ target: ProtocolDeclSyntax) -> InheritanceClauseSyntax {
		let type = InheritedTypeSyntax(type: IdentifierTypeSyntax(name: target.name))
		return InheritanceClauseSyntax(inheritedTypes: .init([type]))
	}

	static func hasStubs(for functions: [FunctionDeclSyntax]) -> Bool {
		return functions.contains {
			$0.signature.returnClause != nil
		}
	}
}
