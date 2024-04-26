@testable import Batch
import Batch.Batch_Private
import Foundation
import XCTest

class UserDataManagerTests: XCTestCase {
    func testModernAttributeMethods() async throws {
        let datasource = MockUserDatasource()

        let overlay = BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)
        defer { removeOverlay(overlay) }

        datasource.expect().call(
            datasource.clearTags()
        )
        datasource.expect().call(
            datasource.clearAttributes()
        )

        await BAUserDataManager._performClearRemoteInstallationData()

        datasource.verify()
    }
}
