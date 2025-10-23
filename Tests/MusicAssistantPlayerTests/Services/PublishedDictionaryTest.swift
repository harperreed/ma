// ABOUTME: Test to verify @Published dictionary mutations trigger objectWillChange
// ABOUTME: Critical test to ensure SwiftUI view updates work with dictionary-based storage

import XCTest
import Combine
@testable import MusicAssistantPlayer

final class PublishedDictionaryTest: XCTestCase {
    class TestObservable: ObservableObject {
        @Published var dict: [String: String] = [:]
    }

    @MainActor
    func testDictionaryMutationTriggersPublished() {
        let observable = TestObservable()
        var changeCount = 0

        let cancellable = observable.objectWillChange.sink { _ in
            changeCount += 1
        }

        // Test 1: Setting a value
        observable.dict["key1"] = "value1"

        // Test 2: Modifying existing value
        observable.dict["key1"] = "value2"

        // Test 3: Removing a value
        observable.dict.removeValue(forKey: "key1")

        // Clean up
        cancellable.cancel()

        // @Published SHOULD trigger on dictionary mutations
        // If this fails, we have a critical bug in LibraryService
        XCTAssertEqual(changeCount, 3, "Dictionary mutations should trigger @Published objectWillChange")
    }

    @MainActor
    func testDictionaryReplaceTriggersPublished() {
        let observable = TestObservable()
        var changeCount = 0

        let cancellable = observable.objectWillChange.sink { _ in
            changeCount += 1
        }

        // Replace entire dictionary
        observable.dict = ["key1": "value1", "key2": "value2"]

        cancellable.cancel()

        XCTAssertEqual(changeCount, 1, "Dictionary replacement should trigger @Published")
    }
}
