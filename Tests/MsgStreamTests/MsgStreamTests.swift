import XCTest
import Foundation
@testable import MsgStream

func headerSizeAssert(bufSize: UInt64, expect: UInt8) -> Void {
    let actual = MsgStreamHeader.sizeForRecvBufOfSize(bufSize)
    XCTAssertEqual(actual, expect)
}

final class MsgStreamTests: XCTestCase {
    func testHeaderSize0Bytes() {
        headerSizeAssert(bufSize: 0, expect: 1)
    }
    
    func testHeaderSize2Bytes() {
        headerSizeAssert(bufSize: 0x01, expect: 2)
        headerSizeAssert(bufSize: 0xff, expect: 2)
    }
    
    func testHeaderSize3Bytes() {
        headerSizeAssert(bufSize: 0x0100, expect: 3)
        headerSizeAssert(bufSize: 0xffff, expect: 3)
    }
    
    func testHeaderSize4Bytes() {
        headerSizeAssert(bufSize: 0x010000, expect: 4)
        headerSizeAssert(bufSize: 0xffffff, expect: 4)
    }
    
    func testHeaderSize5Bytes() {
        headerSizeAssert(bufSize: 0x01000000, expect: 5)
        headerSizeAssert(bufSize: 0xffffffff, expect: 5)
    }
    
    func testHeaderSize6Bytes() {
        headerSizeAssert(bufSize: 0x0100000000, expect: 6)
        headerSizeAssert(bufSize: 0xffffffffff, expect: 6)
    }
    
    func testHeaderSize7Bytes() {
        headerSizeAssert(bufSize: 0x010000000000, expect: 7)
        headerSizeAssert(bufSize: 0xffffffffffff, expect: 7)
    }
    
    func testHeaderSize8Bytes() {
        headerSizeAssert(bufSize: 0x01000000000000, expect: 8)
        headerSizeAssert(bufSize: 0xffffffffffffff, expect: 8)
    }
    
    func testHeaderSize9Bytes() {
        headerSizeAssert(bufSize: 0x0100000000000000, expect: 9)
        headerSizeAssert(bufSize: 0xffffffffffffffff, expect: 9)
    }
    
    func testSendsAndReceivesSingleMessage() throws {
        let streams = MemStreams()
        
        var msg = TestMessage()
        msg.id = 24
        msg.type = "test"
        
        try msg.send(streams:streams)
        streams.copyOutputToInput()
        try msg.assertRecvEqual(streams: streams)
    }
    
    func testSendsAndReceivesTwoMessages() throws {
        let streams = MemStreams()
        
        var msg = TestMessage()
        msg.id = 24
        msg.type = "test"
        
        try msg.send(streams:streams)
        try msg.send(streams:streams)
        streams.copyOutputToInput()
        try msg.assertRecvEqual(streams: streams)
        try msg.assertRecvEqual(streams: streams)
    }
    
    func testCanSendData() throws {
        let buf = Data([1, 2, 3])
        let streams = MemStreams()
        try streams.sender.send(buf, recvBufSize: 32)
        let outData = streams.outputData()
        XCTAssertEqual(outData, Data([2, 3, 1, 2, 3]))
    }
    
    func testCanSendArray() throws {
        let buf: [UInt8] = [1, 2, 3]
        let streams = MemStreams()
        try streams.sender.send(buf, recvBufSize: 32)
        let outData = streams.outputData()
        XCTAssertEqual(outData, Data([2, 3, 1, 2, 3]))
    }
    
    func testCanSendArraySlice() throws {
        var buf = [UInt8].init(repeating:0, count:32)
        buf.replaceSubrange(..<3, with: [1, 2, 4])
        let slice = buf[..<3]
        
        let streams = MemStreams()
        try streams.sender.send(slice, recvBufSize: buf.count)
        let outData = streams.outputData()
        XCTAssertEqual(outData, Data([2, 3, 1, 2, 4]))
    }
    
    func testCanSendContiguousArray() throws {
        let buf = ContiguousArray<UInt8>([3, 2, 1])
        
        let streams = MemStreams()
        try streams.sender.send(buf, recvBufSize: 32)
        let outData = streams.outputData()
        XCTAssertEqual(outData, Data([2, 3, 3, 2, 1]))
    }
    
    func testCanRecvData() throws {
        let streams = MemStreams()
        streams.copyToInput(data:Data([2, 3, 3, 2, 1]))
        
        var buf = Data(count:32)
        let n = try streams.receiver.receive(&buf)
        XCTAssertEqual(buf[..<n], Data([3, 2, 1]))
    }
    
    func testCanRecvArray() throws {
        let streams = MemStreams()
        streams.copyToInput(data:Data([2, 4, 4, 3, 2, 1]))
        
        var buf = [UInt8].init(repeating:0, count:32)
        let n = try streams.receiver.receive(&buf)
        XCTAssertEqual(buf[..<Int(n)], [4, 3, 2, 1])
    }
    
    func testCanRecvArraySlice() throws {
        let streams = MemStreams()
        streams.copyToInput(data:Data([2, 4, 4, 3, 2, 1]))
        
        var buf = [UInt8].init(repeating:0, count:64)
        let n = try streams.receiver.receive(&buf[32...])
        XCTAssertEqual(buf[32..<32+Int(n)], [4, 3, 2, 1])
    }
    
    func testCanRecvContiguousArray() throws {
        let streams = MemStreams()
        streams.copyToInput(data:Data([2, 5, 1, 2, 3, 4, 5]))
        
        var buf = ContiguousArray<UInt8>(repeating:0,count:32)
        let n = try streams.receiver.receive(&buf)
        XCTAssertEqual(buf[..<Int(n)], [1, 2, 3, 4, 5])
    }
}

struct TestMessage : Codable, Equatable {
    public var id: Int
    public var type: String
    private static let bufSize = 2048
    
    init() {
        self.id = 0
        self.type = ""
    }
    
    public func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    public static func fromJSON(json: Data) throws -> TestMessage {
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from:json)
    }
    
    public func send(streams: MemStreams) throws -> Void {
        let sendJson = try self.toJSON()
        try streams.sender.send(sendJson, recvBufSize: Self.bufSize)
    }
    
    public func assertRecvEqual(streams: MemStreams) throws -> Void {
        var buf = Data(count:Self.bufSize)
        let n = try streams.receiver.receive(&buf)
        buf.count = Int(n)
        let msgRecv = try TestMessage.fromJSON(json:buf)
        XCTAssertEqual(self, msgRecv)
    }
}

class MemStreams {
    public var input: InputStream
    public var output: OutputStream
    public var sender: StreamMsgSender
    public var receiver: StreamMsgReceiver
    
    init() {
        self.output = OutputStream.toMemory()
        self.sender = StreamMsgSender(stream: self.output)
        self.output.open()
        
        self.input = InputStream(data:Data())
        self.receiver = StreamMsgReceiver(stream: self.input)
        self.input.open()
    }
    
    public func outputData() -> Data {
        self.output.property(forKey:Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data
    }
    
    public func copyOutputToInput() -> Void {
        self.input.close()
        let data = self.outputData()
        self.copyToInput(data:data)
    }
    
    public func copyToInput(data: Data) -> Void {
        self.input = InputStream(data:data)
        self.receiver = StreamMsgReceiver(stream: self.input)
        self.input.open()
    }
    
    deinit {
        self.output.close()
        self.input.close()
    }
}
