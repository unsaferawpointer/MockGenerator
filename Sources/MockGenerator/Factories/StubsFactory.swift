//
//  StubsFactory.swift
//  
//
//  Created by Anton Cherkasov on 26.05.2024.
//

import SwiftSyntax
import SwiftBasicFormat

final class StubsFactory { }

extension StubsFactory {

	static func makeStruct(
		for functions: [FunctionDeclSyntax],
		with data: MacrosData,
		configuration: Configuration.Stub
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
			name: configuration.token,
			memberBlock: memberBlock
		)
	}

	static func makeVariable(with configuration: Configuration.Stub) -> VariableDeclSyntax {

		let identifier = IdentifierPatternSyntax(identifier: .identifier(configuration.variable))

		let stubType = IdentifierTypeSyntax(name: configuration.token)

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

	static func makeBlock(
		for function: FunctionDeclSyntax,
		with data: MacrosData,
		andConfiguration configuration: Configuration.Stub
	) -> CodeBlockItemSyntax {

		let identifierPattern = IdentifierPatternSyntax(identifier: .identifier("stub"))

		let variable = DeclReferenceExprSyntax(baseName: .identifier(configuration.variable))
		let stubName = DeclReferenceExprSyntax(baseName: data[function.signature].name)

		let memberAccessExprSyntax = MemberAccessExprSyntax(
			base: variable,
			period: .periodToken(),
			declName: stubName
		)

		let initializer = InitializerClauseSyntax(
			equal: .equalToken(), value: memberAccessExprSyntax)

		let condition = OptionalBindingConditionSyntax(
			bindingSpecifier: .keyword(.let),
			pattern: identifierPattern,
			initializer: initializer
		)

		let conditionElement = ConditionElementSyntax(condition: .optionalBinding(condition))
		let conditionElementListSyntax = ConditionElementListSyntax([conditionElement])
		let guardStmtSyntax = GuardStmtSyntax(conditions: conditionElementListSyntax, body: makeElseBlock())

		return CodeBlockItemSyntax(item: .init(guardStmtSyntax))
	}
}

// MARK: - Helpers
private extension StubsFactory {

	static func makeElseBlock() -> CodeBlockSyntax {
		let function = DeclReferenceExprSyntax(baseName: .identifier("fatalError"))
		let funtionCall = FunctionCallExprSyntax(
			calledExpression: function,
			leftParen: .leftParenToken(),
			arguments: .init([]),
			rightParen: .rightParenToken(),
			additionalTrailingClosures: .init([])
		)
		let item = CodeBlockItemSyntax(item: .init(funtionCall))
		let statements = CodeBlockItemListSyntax([item])
		return CodeBlockSyntax(statements: statements)
	}
}
