import XCTest

final class BoundaryImportTests: XCTestCase {
    func testClerkAndSupabaseImportsStayBehindBoundaries() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appRoot = projectRoot.appendingPathComponent("Wander")
        let swiftFiles = try Self.swiftFiles(in: appRoot)

        let clerkAllowed: Set<String> = [
            "Wander/Features/Auth/AuthGateSheet.swift",
            "Wander/Services/Auth/ClerkAuthService.swift"
        ]
        let supabaseAllowed: Set<String> = [
            "Wander/Services/Remote/WanderSupabaseClient.swift"
        ]

        for file in swiftFiles {
            let relativePath = file.path.replacingOccurrences(of: projectRoot.path + "/", with: "")
            let contents = try String(contentsOf: file)

            if contents.contains("import ClerkKit") || contents.contains("import ClerkKitUI") {
                XCTAssertTrue(clerkAllowed.contains(relativePath), "Unexpected Clerk import in \(relativePath)")
            }

            if contents.contains("import Supabase") {
                XCTAssertTrue(supabaseAllowed.contains(relativePath), "Unexpected Supabase import in \(relativePath)")
            }
        }
    }

    private static func swiftFiles(in root: URL) throws -> [URL] {
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: Array(resourceKeys)) else {
            return []
        }

        return try enumerator.compactMap { item in
            guard let url = item as? URL, url.pathExtension == "swift" else { return nil }
            let values = try url.resourceValues(forKeys: resourceKeys)
            return values.isRegularFile == true ? url : nil
        }
    }
}
