import XCTest
@testable import Wander

final class ExtractionCandidateFilterTests: XCTestCase {
    func testConfirmableCandidatesRequireJobAndCandidateConfidence() {
        let result = ExtractionJobResult(
            extractionJobID: "job_remote",
            status: .needsConfirmation,
            attemptCount: 1,
            providerSteps: ["worker_started"],
            candidates: [
                PlaceCandidate(
                    id: "good",
                    name: "Good Coffee",
                    category: "coffee",
                    latitude: 34.0,
                    longitude: -118.0,
                    confidence: 0.82
                ),
                PlaceCandidate(
                    id: "low",
                    name: "Maybe Coffee",
                    category: "coffee",
                    latitude: 34.1,
                    longitude: -118.1,
                    confidence: 0.55
                )
            ],
            confidence: 0.81,
            errorCode: nil,
            errorMessage: nil
        )

        XCTAssertEqual(ExtractionCandidateFilter.confirmableCandidates(from: result).map(\.id), ["good"])
    }

    func testLowConfidenceExtractionDoesNotConfirm() {
        let result = ExtractionJobResult(
            extractionJobID: "job_remote",
            status: .needsConfirmation,
            attemptCount: 1,
            providerSteps: ["worker_started"],
            candidates: [
                PlaceCandidate(
                    id: "candidate",
                    name: "Maybe Coffee",
                    category: "coffee",
                    latitude: 34.0,
                    longitude: -118.0,
                    confidence: 0.86
                )
            ],
            confidence: 0.49,
            errorCode: nil,
            errorMessage: nil
        )

        XCTAssertTrue(ExtractionCandidateFilter.confirmableCandidates(from: result).isEmpty)
    }

    func testNoPlaceFoundExtractionDoesNotConfirm() {
        let result = ExtractionJobResult(
            extractionJobID: "job_remote",
            status: .noPlaceFound,
            attemptCount: 1,
            providerSteps: ["worker_started"],
            candidates: [
                PlaceCandidate(
                    id: "candidate",
                    name: "Maybe Coffee",
                    category: "coffee",
                    latitude: 34.0,
                    longitude: -118.0,
                    confidence: 0.86
                )
            ],
            confidence: 0.9,
            errorCode: nil,
            errorMessage: nil
        )

        XCTAssertTrue(ExtractionCandidateFilter.confirmableCandidates(from: result).isEmpty)
    }
}
