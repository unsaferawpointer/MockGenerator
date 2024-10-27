//
//  StubsFactory.swift
//  
//
//  Created by Anton Cherkasov on 26.05.2024.
//

import SwiftSyntax
import SwiftBasicFormat

final class StubsFactory { 

	let configuration: MockConfiguration.Stub

	// MARK: - Initialization

	init(configuration: MockConfiguration.Stub) {
		self.configuration = configuration
	}
}

extension StubsFactory {

	func makeStruct(
		for functions: [FunctionDeclSyntax],
		with data: MacrosData
	) -> StructDeclSyntax? {

		let variables = functions
			.map(\.signature)
			.compactMap { signature -> VariableDeclSyntax? in
				guard let type = signature.returnClause?.type else {
					return nil
				}

				let name = data[signature].name

				let resultType: TypeSyntaxProtocol = type.is(OptionalTypeSyntax.self)
					? type
					: OptionalTypeSyntax(wrappedType: type)

				let pattern = PatternBindingSyntax(
					pattern: IdentifierPatternSyntax(identifier: name),
					typeAnnotation: TypeAnnotationSyntax(type: resultType)
				)

				return VariableDeclSyntax(
					modifiers: DeclModifierListSyntax([]),
					bindingSpecifier: .keyword(.var),
					bindings: PatternBindingListSyntax([pattern])
				)
			}
			.map {
				MemberBlockItemSyntax(decl: $0)
			}

		guard !variables.isEmpty else {
			return nil
		}

		let members = MemberBlockItemListSyntax(variables)
		let memberBlock = MemberBlockSyntax(members: members)

		return StructDeclSyntax(
			name: .identifier(configuration.type),
			memberBlock: memberBlock
		)
	}

	func makeVariable() -> VariableDeclSyntax {

		let identifier = IdentifierPatternSyntax(identifier: .identifier(configuration.variable))

		let stubType = IdentifierTypeSyntax(name: .identifier(configuration.type))

		let type = TypeAnnotationSyntax(type: stubType)

		let functionCallExprSyntax = FunctionCallExprSyntax(
			calledExpression: DeclReferenceExprSyntax(baseName: .identifier(configuration.type)),
			leftParen: .leftParenToken(),
			arguments: LabeledExprListSyntax([]),
			rightParen: .rightParenToken(),
			additionalTrailingClosures: []
		)
		let initializer = InitializerClauseSyntax(value: functionCallExprSyntax)

		let pattern = PatternBindingSyntax(
			pattern: identifier,
			typeAnnotation: type,
			initializer: initializer
		)

		return VariableDeclSyntax(
			modifiers: DeclModifierListSyntax([]),
			bindingSpecifier: .keyword(.var),
			bindings: PatternBindingListSyntax([pattern])
		)
	}

	func makeBlock(for function: FunctionDeclSyntax, with data: MacrosData) -> CodeBlockItemSyntax {

		let initializer = InitializerClauseSyntax(
			value: MemberAccessExprSyntax(
				base: DeclReferenceExprSyntax(
					baseName: .identifier(configuration.variable)
				),
				declName: DeclReferenceExprSyntax(
					baseName: data[function.signature].name
				)
			)
		)

		let condition = ConditionElementSyntax(
			condition: .optionalBinding(
				OptionalBindingConditionSyntax(
					bindingSpecifier: .keyword(.let),
					pattern: IdentifierPatternSyntax(identifier: .identifier("stub")),
					initializer: initializer
				)
			)
		)

		let statement = CodeBlockItemSyntax(
			item: .init(
				FunctionCallExprSyntax(
					calledExpression: DeclReferenceExprSyntax(
						baseName: .identifier("fatalError")
					),
					leftParen: .leftParenToken(),
					arguments: .init([]),
					rightParen: .rightParenToken(),
					additionalTrailingClosures: .init([])
				)
			)
		)

		return CodeBlockItemSyntax(
			item: .init(
				GuardStmtSyntax(
					conditions: ConditionElementListSyntax([condition]),
					body: CodeBlockSyntax(
						statements: CodeBlockItemListSyntax([statement])
					)
				)
			)
		)
	}
}
