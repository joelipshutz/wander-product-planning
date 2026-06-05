import XCTest
@testable import Wander

@MainActor
final class RemoteRepositoryTests: XCTestCase {
    func testProfileSearchCallsExpectedRPCAndMapsShells() async throws {
        let rpc = RecordingRPC()
        rpc.responses["search_profiles_by_handle"] = """
        [
          {
            "id": "user_maya",
            "handle": "maya",
            "display_name": "Maya Chen",
            "avatar_url": null,
            "bio": "coffee and hikes",
            "home_area": "Los Angeles"
          }
        ]
        """.data(using: .utf8)
        let repository = SupabaseProfileRepository(rpc: rpc)

        let profiles = try await repository.searchProfiles(handleQuery: "ma")

        XCTAssertEqual(profiles.map(\.handle), ["maya"])
        XCTAssertEqual(profiles[0].displayName, "Maya Chen")
        XCTAssertEqual(profiles[0].relationship, .nonFollower)
        XCTAssertEqual(rpc.calls.map(\.name), ["search_profiles_by_handle"])
        XCTAssertEqual(rpc.calls[0].body["query"] as? String, "ma")
    }

    func testVisiblePlacesCallRPCWithSnakeCaseParamsAndMapRows() async throws {
        let rpc = RecordingRPC()
        rpc.responses["visible_places_in_view"] = """
        [
          {
            "user_place_id": "up_1",
            "place_id": "place_1",
            "owner_user_id": "user_maya",
            "owner_handle": "maya",
            "owner_display_name": "Maya Chen",
            "canonical_name": "Griffith Observatory Trail",
            "category": "hike",
            "latitude": 34.1184,
            "longitude": -118.3004,
            "status": "been",
            "visibility": "followers",
            "note": "Easy sunset win.",
            "rating_signal": "great",
            "source_type": "manual",
            "attributes": [
              {
                "question_definition_id": "q_1",
                "question_key": "strenuousness",
                "value_type": "single_choice",
                "value": "easy",
                "prompt": "how hard?",
                "options": ["easy", "medium"],
                "is_system": true
              }
            ]
          }
        ]
        """.data(using: .utf8)
        let repository = SupabasePlaceRepository(rpc: rpc)

        let places = try await repository.places(
            in: MapViewport(minLatitude: 34, minLongitude: -119, maxLatitude: 35, maxLongitude: -118)
        )

        XCTAssertEqual(places.map { $0.place.canonicalName }, ["Griffith Observatory Trail"])
        XCTAssertEqual(places[0].userPlace.status, .been)
        XCTAssertEqual(places[0].userPlace.visibility, .followers)
        XCTAssertEqual(rpc.calls.map(\.name), ["visible_places_in_view"])
        XCTAssertEqual(rpc.calls[0].body["min_lat"] as? Double, 34)
        XCTAssertEqual(rpc.calls[0].body["max_lng"] as? Double, -118)
        XCTAssertNil(rpc.calls[0].body["owner_scope"] as Any?)
    }

    func testVisiblePlacesRejectUnknownStatus() async throws {
        let rpc = RecordingRPC()
        rpc.responses["visible_places_in_view"] = """
        [
          {
            "user_place_id": "up_1",
            "place_id": "place_1",
            "owner_user_id": "user_maya",
            "owner_handle": "maya",
            "owner_display_name": "Maya Chen",
            "canonical_name": "Bad Row",
            "category": "hike",
            "latitude": 34.1,
            "longitude": -118.3,
            "status": "maybe",
            "visibility": "followers",
            "note": null,
            "rating_signal": null,
            "source_type": "manual",
            "attributes": []
          }
        ]
        """.data(using: .utf8)
        let repository = SupabasePlaceRepository(rpc: rpc)

        do {
            _ = try await repository.places(
                in: MapViewport(minLatitude: 34, minLongitude: -119, maxLatitude: 35, maxLongitude: -118)
            )
            XCTFail("Expected invalid status to throw")
        } catch let error as WanderRemoteError {
            guard case .invalidResponse(let message) = error else {
                return XCTFail("Unexpected remote error: \(error)")
            }
            XCTAssertTrue(message.contains("Unknown place status"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSocialSaveCallsExpectedRPC() async throws {
        let rpc = RecordingRPC()
        rpc.responses["save_visible_place"] = #"{"user_place_id":"up_saved"}"#.data(using: .utf8)
        let repository = SupabaseUserPlaceRepository(rpc: rpc)

        let result = try await repository.saveVisiblePlace(placeID: "place_1", sourceUserPlaceID: "up_source")

        XCTAssertEqual(result, SaveResult(userPlaceID: "up_saved", syncState: .synced))
        XCTAssertEqual(rpc.calls.map(\.name), ["save_visible_place"])
        XCTAssertEqual(rpc.calls[0].body["input_place_id"] as? String, "place_1")
        XCTAssertEqual(rpc.calls[0].body["input_source_user_place_id"] as? String, "up_source")
    }

    func testOwnPlaceSaveCallsExpectedRPCWithPlaceAndAttributes() async throws {
        let rpc = RecordingRPC()
        rpc.responses["save_own_place"] = #"{"user_place_id":"up_saved","place_id":"place_saved"}"#.data(using: .utf8)
        let repository = SupabaseUserPlaceRepository(rpc: rpc)
        let draft = UserPlaceDraft(
            place: PlaceDraft(
                localID: "local_place_maru",
                serverID: nil,
                canonicalName: "Maru Coffee",
                category: "coffee",
                address: nil,
                locality: "Los Angeles",
                region: "CA",
                country: nil,
                latitude: 34.045,
                longitude: -118.235,
                sourceProvider: "mapkit",
                sourceProviderPlaceID: "mk_maru",
                confidence: 0.92
            ),
            status: .been,
            visibility: .followers,
            note: "window table",
            ratingSignal: "great",
            nearbyConfirmed: true,
            sourceType: "current_location",
            attributes: [
                PlaceAttributeDraft(questionKey: "rating_signal", valueType: "emoji_scale", stringValue: "great"),
                PlaceAttributeDraft(questionKey: "coffee_tags", valueType: "multi_tag", stringValues: ["wifi solid", "quiet"])
            ]
        )

        let result = try await repository.save(draft)

        XCTAssertEqual(result, SaveResult(userPlaceID: "up_saved", syncState: .synced, placeID: "place_saved"))
        XCTAssertEqual(rpc.calls.map(\.name), ["save_own_place"])

        let body = rpc.rawBodies[0]
        let place = body["input_place"] as? [String: Any]
        XCTAssertEqual(place?["canonical_name"] as? String, "Maru Coffee")
        XCTAssertEqual(place?["source_provider_place_id"] as? String, "mk_maru")
        XCTAssertEqual(place?["latitude"] as? Double, 34.045)

        let userPlace = body["input_user_place"] as? [String: Any]
        XCTAssertEqual(userPlace?["status"] as? String, "been")
        XCTAssertEqual(userPlace?["visibility"] as? String, "followers")
        XCTAssertEqual(userPlace?["nearby_confirmed"] as? Bool, true)

        let attributes = body["input_attributes"] as? [[String: Any]]
        XCTAssertEqual(attributes?.map { $0["question_key"] as? String }, ["rating_signal", "coffee_tags"])
        XCTAssertEqual(attributes?.first?["value"] as? String, "great")
        XCTAssertEqual(attributes?[1]["value"] as? [String], ["wifi solid", "quiet"])
    }

    func testUnblockCallsExpectedRPC() async throws {
        let rpc = RecordingRPC()
        let repository = SupabaseBlockRepository(rpc: rpc)

        try await repository.unblock(userID: "user_ryan")

        XCTAssertEqual(rpc.calls.map(\.name), ["unblock_user"])
        XCTAssertEqual(rpc.calls[0].body["profile_id"] as? String, "user_ryan")
    }
}

@MainActor
private final class RecordingRPC: RemoteProcedureCalling {
    struct Call: Equatable {
        let name: String
        let body: [String: AnyHashable]
    }

    var responses: [String: Data] = [:]
    private(set) var rawBodies: [[String: Any]] = []
    private(set) var calls: [Call] = []

    func call<Value: Decodable, Params: Encodable>(
        _ name: String,
        params: Params,
        decoder: JSONDecoder
    ) async throws -> Value {
        let body = try encodedObject(params)
        rawBodies.append(body)
        calls.append(Call(name: name, body: anyHashableBody(body)))

        if Value.self == EmptyRPCResponse.self {
            return EmptyRPCResponse() as! Value
        }

        guard let data = responses[name] else {
            throw WanderRemoteError.invalidResponse("Missing fake response for \(name)")
        }

        return try decoder.decode(Value.self, from: data)
    }

    private func encodedObject<Params: Encodable>(_ params: Params) throws -> [String: Any] {
        let data = try JSONEncoder().encode(params)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }

        return object
    }

    private func anyHashableBody(_ object: [String: Any]) -> [String: AnyHashable] {
        return object.reduce(into: [:]) { result, element in
            if let value = element.value as? AnyHashable {
                result[element.key] = value
            } else if element.value is NSNull {
                result[element.key] = nil
            }
        }
    }
}
