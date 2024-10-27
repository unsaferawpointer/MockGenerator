//
//  MockGeneratorProtocol.swift
//
//
//  Created by Anton Cherkasov on 04.08.2024.
//

public protocol MockGeneratorProtocol {

	/// Generate mock from source
	///
	/// - Parameters:
	///   - source: Code source
	/// - Returns: Returns formatted mocks code
	func generate(for source: String) throws -> String
}
