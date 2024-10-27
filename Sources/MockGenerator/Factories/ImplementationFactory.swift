//
//  ImplementationFactory.swift
//  
//
//  Created by Anton Cherkasov on 03.08.2024.
//

import SwiftSyntax

final class ImplementationFactory {

	let configuration: MockConfiguration

	// MARK: - Initialization

	init(configuration: MockConfiguration) {
		self.configuration = configuration
	}
}

extension ImplementationFactory {

	func makeImplementation(protocolDecl: ProtocolDeclSyntax) -> ExtensionDeclSyntax {
		let comment = "// MARK: - \(protocolDecl.name.text)"
		let leadingTrivia: Trivia = [.newlines(2), .lineComment(comment), .newlines(1)]

		let type = IdentifierTypeSyntax(name: protocolDecl.name)
		let inheritedTypes = InheritedTypeListSyntax([InheritedTypeSyntax(type: type)])
		let inheritanceClauseSyntax = InheritanceClauseSyntax(inheritedTypes: inheritedTypes)

		let functions: [FunctionDeclSyntax] = protocolDecl.memberBlock.members
			.compactMap {
				$0.decl.as(FunctionDeclSyntax.self)
			}

		// TODO: - Add Dependency Injection
		let data = DataFactory().makeData(from: functions, mockName: "\(protocolDecl.name.text)Mock")

		let implementations = makeFunctions(for: functions, with: data)

		let members = implementations.map {
			MemberBlockItemSyntax(decl: $0)
		}

		return ExtensionDeclSyntax(
			leadingTrivia: leadingTrivia,
			extendedType: IdentifierTypeSyntax(name: .identifier("\(protocolDecl.name.text)Mock")),
			inheritanceClause: inheritanceClauseSyntax,
			memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax(members))
		)
	}
}

private extension ImplementationFactory {

	func makeFunctions(for functions: [FunctionDeclSyntax], with data: MacrosData) -> [FunctionDeclSyntax] {
		return functions.map { function -> FunctionDeclSyntax in

			var body = CodeBlockItemListSyntax([])

			let invocationBlock = makeInvocationBlock(for: function, data: data)
			body.append(invocationBlock)

			if let errorBlock = makeErrorBlock(for: function, data: data) {
				body.append(errorBlock)
			}

			if let conditionBlock = makeConditionBlock(for: function, data: data) {
				body.append(conditionBlock)
			}

			if let returnBlock = makeReturn(for: function, data: data) {
				body.append(returnBlock)
			}

			return FunctionDeclSyntax(
				name: function.name,
				signature: function.signature,
				body: CodeBlockSyntax(statements: body)
			)
		}
	}

	func makeInvocationBlock(for function: FunctionDeclSyntax, data: MacrosData) -> CodeBlockItemSyntax {

		let info = data[function.signature]

		var labeledExprListSyntax = LabeledExprListSyntax()

		for parameter in info.parameters {
			let label = LabeledExprSyntax(
				label: parameter.name,
				colon: .colonToken(),
				expression: DeclReferenceExprSyntax(baseName: parameter.name),
				trailingComma: parameter.isLast ? nil : .commaToken()
			)
			labeledExprListSyntax.append(label)
		}

		let functionCallExpr = FunctionCallExprSyntax(
			calledExpression: MemberAccessExprSyntax(
				declName: DeclReferenceExprSyntax(
					baseName: info.name,
					argumentNames: nil
				)
			),
			leftParen: info.parameters.isEmpty ? nil : .leftParenToken(),
			arguments: labeledExprListSyntax,
			rightParen: info.parameters.isEmpty ? nil : .rightParenToken()
		)

		let functionCall = FunctionCallExprSyntax(
			calledExpression: MemberAccessExprSyntax(
				base: DeclReferenceExprSyntax(
					baseName: .identifier(configuration.action.variable)
				),
				declName: DeclReferenceExprSyntax(
					baseName: .identifier("append")
				)
			),
			leftParen: .leftParenToken(),
			arguments: LabeledExprListSyntax(
				[
					LabeledExprSyntax(expression: functionCallExpr)
				]
			),
			rightParen: .rightParenToken()
		)

		return CodeBlockItemSyntax(item: .expr(ExprSyntax(functionCall)))
	}

	func makeErrorBlock(for function: FunctionDeclSyntax, data: MacrosData) -> CodeBlockItemSyntax? {
		guard function.signature.effectSpecifiers?.throwsSpecifier != nil else {
			return nil
		}
		return ErrorsFactory.makeBlock(for: function, with: data, configuration: configuration.errors)
	}

	func makeReturn(for function: FunctionDeclSyntax, data: MacrosData) -> CodeBlockItemSyntax? {

		guard let returnClause = function.signature.returnClause else {
			return nil
		}

		let returnSyntax = if !returnClause.type.is(OptionalTypeSyntax.self) {
			ReturnStmtSyntax(
				expression: DeclReferenceExprSyntax(
					baseName: .identifier("stub")
				)
			)
		} else {
			ReturnStmtSyntax(
				expression: MemberAccessExprSyntax(
					base: DeclReferenceExprSyntax(
						baseName: .identifier(configuration.stub.variable)
					),
					declName: DeclReferenceExprSyntax(
						baseName: data[function.signature].name
					)
				)
			)
		}

		return CodeBlockItemSyntax(item: .stmt(StmtSyntax(returnSyntax)))
	}

	func makeConditionBlock(for function: FunctionDeclSyntax, data: MacrosData) -> CodeBlockItemSyntax? {

		guard 
			let type = function.signature.returnClause?.type,
			!type.is(OptionalTypeSyntax.self)
		else {
			return nil
		}

		let identifierPattern = IdentifierPatternSyntax(
			identifier: .identifier("stub")
		)

		let variable = DeclReferenceExprSyntax(baseName: .identifier(configuration.stub.variable))
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

	func makeElseBlock() -> CodeBlockSyntax {
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
