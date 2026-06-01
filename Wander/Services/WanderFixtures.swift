import Foundation
import SwiftData

struct WanderFixtures {
    let currentUser: LocalProfile
    let profiles: [LocalProfile]
    let places: [LocalPlace]
    let userPlaces: [LocalUserPlace]
    let contactProvider: FakeContactProvider

    nonisolated(unsafe) static let seed: WanderFixtures = {
        let currentUser = LocalProfile(id: "user_joe", displayName: "Joe", handle: "joe", bio: "Coffee, hikes, good tables.")
        let maya = LocalProfile(id: "user_maya", displayName: "Maya", handle: "maya", homeArea: "LA")
        let ryan = LocalProfile(id: "user_ryan", displayName: "Ryan", handle: "ryan", homeArea: "Brooklyn")

        let coffee = LocalPlace(id: "place_woodcat", canonicalName: "Woodcat Coffee", category: "coffee", latitude: 34.077, longitude: -118.260, provider: "mapkit")
        let hike = LocalPlace(id: "place_griffith", canonicalName: "Griffith Observatory Trail", category: "hike", latitude: 34.119, longitude: -118.300, provider: "mapkit")
        let noodles = LocalPlace(id: "place_noodles", canonicalName: "Larchmont Noodles", category: "restaurant", latitude: 34.073, longitude: -118.323, provider: "mapkit")

        let userPlaces = [
            LocalUserPlace(id: "up_joe_woodcat", userID: currentUser.id, placeID: coffee.id, status: .been, visibility: .followers, note: "Good morning table by the window.", nearbyConfirmed: true, sourceType: "manual", syncState: .localOnly),
            LocalUserPlace(id: "up_maya_griffith", userID: maya.id, placeID: hike.id, status: .been, visibility: .followers, note: "Easy sunset win.", nearbyConfirmed: true, sourceType: "social_seed", syncState: .synced),
            LocalUserPlace(id: "up_ryan_noodles", userID: ryan.id, placeID: noodles.id, status: .wannaGo, visibility: .mutuals, note: "Saved for a rainy night.", sourceType: "social_seed", syncState: .synced)
        ]

        let contacts = FakeContactProvider(seededMatches: [
            ContactMatch(id: "contact_maya", displayName: "Maya", handle: "maya", userID: maya.id),
            ContactMatch(id: "contact_sam", displayName: "Sam", handle: nil, userID: nil)
        ])

        return WanderFixtures(
            currentUser: currentUser,
            profiles: [currentUser, maya, ryan],
            places: [coffee, hike, noodles],
            userPlaces: userPlaces,
            contactProvider: contacts
        )
    }()
}

enum WanderModelContainer {
    static var preview: ModelContainer {
        let schema = Schema([
            LocalProfile.self,
            LocalFollow.self,
            LocalBlock.self,
            LocalPlace.self,
            LocalUserPlace.self,
            LocalPlaceAttribute.self,
            LocalSourceArtifact.self,
            LocalExtractionJob.self,
            SyncOperation.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }
}
