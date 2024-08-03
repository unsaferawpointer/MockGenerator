//
//  DataFactory.swift
//
//
//  Created by Anton Cherkasov on 13.05.2024.
//

import SwiftSyntax

final class DataFactory { }

extension DataFactory {
	
	func makeData(from functions: [FunctionDeclSyntax], mockName: String) -> MacrosData {

		let nameResolver = NameResolver()

		var map: [FunctionSignatureSyntax: Int] = [:]
		var cases: [FunctionData] = []

		for (index, function) in functions.enumerated() {

			let name = nameResolver.resolve(function.name)
			let parameters = makeParameters(from: function)

			let throwsError = function.signature.effectSpecifiers?.throwsSpecifier != nil
			let isAsync = function.signature.effectSpecifiers?.asyncSpecifier != nil

			let functionData = FunctionData(
				name: name,
				isAsync: isAsync,
				throwsError: throwsError,
				parameters: parameters
			)

			map[function.signature] = index
			cases.append(functionData)
		}

		return MacrosData(mockName: mockName, map: map, cases: cases)
	}
}

// MARK: - Helpers
private extension DataFactory {

	func makeParameters(from function: FunctionDeclSyntax) -> [Parameter] {

		var result = [Parameter]()
		let parameters = function.signature.parameterClause.parameters

		let nameResolver = NameResolver()

		for (index, parameter) in parameters.enumerated() {

			let isLast = parameters.count - 1 == index

			let name = nameResolver.resolve(parameter.usedName)

			// Skip attributes
			let type = parameter.type.as(AttributedTypeSyntax.self)?.baseType ?? parameter.type

			let element = Parameter(
				name: name,
				type: type,
				isLast: isLast
			)

			result.append(element)
		}

		return result
	}
}
