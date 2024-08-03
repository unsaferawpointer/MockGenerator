import XCTest
@testable import MockGenerator

final class MockGeneratorTests: XCTestCase {

	var sut: Generator!

	override func setUp() {
		self.sut = Generator()
	}

	override func tearDown() {
		self.sut = nil
	}
}

extension MockGeneratorTests {

	func test_generate() throws {
		// Arrange
		let source =
		"""
		protocol TestProtocol {
			func getString(for index: Int) throws -> String
			func getInteger() -> Int?
		}
		"""

		let expectedResult =
		"""
		struct Stubs {
		    var getString: String?
		    var getInteger: Int?
		}
		"""

		// Act
		let result = try sut.generate(for: source)

		print(result)

		// Assert
		XCTAssertEqual(result, expectedResult)
	}
}
