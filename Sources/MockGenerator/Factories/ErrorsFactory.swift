//
//  ErrorsFactory.swift
//
//
//  Created by Anton Cherkasov on 06.06.2024.
//

import SwiftSyntax

final class ErrorsFactory { }

extension ErrorsFactory {

	static func makeStruct(
		for functions: [FunctionDeclSyntax],
		with data: MacrosData,
		configuration: Configuration.Errors
	) -> StructDeclSyntax? {

		let variables = functions.compactMap { function -> FunctionSignatureSyntax? in
			guard function.signature.effectSpecifiers?.throwsSpecifier != nil else {
				return nil
			}
			return function.signature
		}.map { signature in
			let name = data[signature].name
			let identifier = IdentifierPatternSyntax(identifier: name)

			let typeAnnotation = TypeAnnotationSyntax(
				colon: .colonToken(),
				type: OptionalTypeSyntax(wrappedType: IdentifierTypeSyntax(name: .identifier("Error")))
			)

			let pattern = PatternBindingSyntax(
				pattern: identifier,
				typeAnnotation: typeAnnotation
			)

			return VariableDeclSyntax(
				modifiers: DeclModifierListSyntax([]),
				bindingSpecifier: .keyword(.var),
				bindings: PatternBindingListSyntax([pattern])
			)
		}.map {
			MemberBlockItemSyntax(decl: $0)
		}

		guard !variables.isEmpty else {
			return nil
		}

		let memberBlockItemList = MemberBlockItemListSyntax(variables)
		let memberBlock = MemberBlockSyntax(members: memberBlockItemList)

		return StructDeclSyntax(
			name: configuration.token,
			memberBlock: memberBlock
		)
	}

	static func makeVariable(with configuration: Configuration.Errors) -> VariableDeclSyntax {

		let identifier = IdentifierPatternSyntax(identifier: .identifier(configuration.variable))

		let errorsType = IdentifierTypeSyntax(name: configuration.token)

		let type = TypeAnnotationSyntax(type: errorsType)

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

	static func makeBlock(for function: FunctionDeclSyntax, with data: MacrosData, configuration: Configuration.Errors) -> CodeBlockItemSyntax {

		let identifierPattern = IdentifierPatternSyntax(identifier: .identifier("error"))

		let errors = DeclReferenceExprSyntax(baseName: .identifier(configuration.variable))
		let functionCall = DeclReferenceExprSyntax(baseName: data[function.signature].name)

		let memberAccessExprSyntax = MemberAccessExprSyntax(base: errors, period: .periodToken(), declName: functionCall)

		let initializer = InitializerClauseSyntax(
			equal: .equalToken(), value: memberAccessExprSyntax)

		let condition = OptionalBindingConditionSyntax(bindingSpecifier: .keyword(.let), pattern: identifierPattern, initializer: initializer)

		let conditionElement = ConditionElementSyntax(condition: .optionalBinding(condition))
		let conditionElementListSyntax = ConditionElementListSyntax([conditionElement])

		let expression = IfExprSyntax(
			ifKeyword: .keyword(.if),
			conditions: conditionElementListSyntax,
			body: makeIfBlockInside()
		)

		let item = ExpressionStmtSyntax(expression: expression)

		return CodeBlockItemSyntax(item: .init(item))
	}

	static func makeIfBlockInside() -> CodeBlockSyntax {

		let expression = DeclReferenceExprSyntax(baseName: .identifier("error"))
		let throwStmt = ThrowStmtSyntax(expression: expression)
		let item = CodeBlockItemSyntax(item: .init(throwStmt))
		let statements = CodeBlockItemListSyntax([item])
		return CodeBlockSyntax(statements: statements)
	}
}

// MARK: - Helpers
private extension ErrorsFactory {

}
