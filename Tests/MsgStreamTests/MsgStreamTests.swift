import XCTest
import Foundation
import CMsgStream

final class MsgStreamTests: XCTestCase {
    func testHeaderSize0Bytes() {
        var hdrSize = 0
        let ec = msgstream_header_size(256, &hdrSize)
        XCTAssertEqual(ec, MSGSTREAM_OK)
        XCTAssertEqual(hdrSize, 3)
    }
}
