import Foundation

// The Swift Programming Language
// https://docs.swift.org/swift-book


/**
 Describes an object that has an underlying buffer of mutable bytes
 */
public protocol MsgHasMutableBytes {
    /**
     Access the object's underlying mutable buffer of bytes
     */
    mutating func withUnsafeMutableBytes<ResultType>(_ body: (UnsafeMutableRawBufferPointer) throws -> ResultType) rethrows -> ResultType
}

/**
 Describes an object that has an underlying buffer of bytes
 */
public protocol MsgHasBytes {
    /**
     Access the object's underlying buffer of bytes
     */
    func withUnsafeBytes<ResultType>(_ body: (UnsafeRawBufferPointer) throws -> ResultType) rethrows -> ResultType
}

extension Data : MsgHasBytes, MsgHasMutableBytes {}
extension [UInt8] : MsgHasBytes, MsgHasMutableBytes {}
extension ContiguousArray<UInt8> : MsgHasBytes, MsgHasMutableBytes {}
extension ArraySlice<UInt8> : MsgHasBytes, MsgHasMutableBytes {}

/**
 An object that can encode and send msgstream messages
 */
public protocol MsgSender {
    /**
     Send a msgstream message
     - Parameters:
        - data: The raw payload of the message (excluding the header)
        - recvBufSize: The size of the receiving buffer, defined by the higher level messaging protocol
     */
    func send<T: MsgHasBytes>(_ data: T, recvBufSize: Int) throws -> Void;
}

/**
 An object that can decode and receive msgstream messages
 */
public protocol MsgReceiver {
    /**
     Receive a msgstream message
     - Parameters:
        - data: The buffer to hold the decoded message payload, whose size is defined by the higher level messaging protocol
     - Returns: The size of the decoded message payload, less than or equal to the size of `data`
     */
    func receive<T: MsgHasMutableBytes>(_ data: inout T) throws -> UInt64;
}

/**
 Represents an error encountered during msgstream operations
 */
public enum MsgStreamError : Error {
    case badData
    case writeFailed(Error?)
    case readFailed(Error?)
    case msgTooBig(msgSize: UInt64, bufSize: UInt64)
}

private func bytesToStore(_ n: UInt64) -> UInt8 {
    var bytes: UInt8 = 0;
    var counter = n;
    while (counter > 0) {
        bytes += 1;
        counter /= 0x100;
    }
    
    return bytes;
}

/**
 Exposes low level functions for working with msgstream headers
 */
public struct MsgStreamHeader {
    /**
     Compute the size of a msgstream header given the receiving buffer size
     - Parameter bufSize: The receiving buffer size
     */
    public static func size(forMsgBufSize bufSize: UInt64) -> UInt8 {
        return bytesToStore(bufSize) + 1;
    }
}

/**
 Send messages over an `OutputStream`
 */
public class StreamMsgSender : MsgSender {
    let stream: OutputStream;
    
    /**
    Initialize the sender with a stream
     - Parameter stream: The stream to send messages through
     */
    init(stream: OutputStream) {
        self.stream = stream
    }
    
    public func send<T: MsgHasBytes>(_ data: T, recvBufSize: Int) throws -> Void {
        try data.withUnsafeBytes() { buf in
            guard let baseAddress = buf.baseAddress else {
                throw MsgStreamError.badData
            }
            
            let headerSize = MsgStreamHeader.size(forMsgBufSize:UInt64(recvBufSize))
            var header = [UInt8].init(repeating:0, count:Int(headerSize))
            header[0] = headerSize
            var n = buf.count
            for i in 1..<Int(headerSize) {
                header[i] = UInt8(n % 0x100)
                n /= 0x100
            }
            
            try writeN(stream:self.stream, buf:header, count:header.count)
            try writeN(stream:self.stream, buf:baseAddress, count:buf.count)
        }
    }
}

/**
 Receive messages through an `InputStream`
 */
public class StreamMsgReceiver : MsgReceiver {
    public let stream: InputStream
    
    /**
     Initialize the receiver with a stream object
     - Parameter stream: The stream to receive messages through
     */
    init(stream: InputStream) {
        self.stream = stream
    }
    
    public func receive<T: MsgHasMutableBytes>(_ data: inout T) throws -> UInt64 {
        return try data.withUnsafeMutableBytes() { (buf: UnsafeMutableRawBufferPointer) throws in
            let headerSize = MsgStreamHeader.size(forMsgBufSize: UInt64(buf.count))
            var header = [UInt8].init(repeating:0,count:Int(headerSize))
            
            guard let hdrPtr = (header.withUnsafeMutableBytes() { buf in buf.baseAddress }) else {
                throw MsgStreamError.badData
            }
            try readN(stream:self.stream, buf:hdrPtr, count:header.count)
            
            if header[0] != headerSize {
                throw MsgStreamError.badData
            }
            
            var msgSize = UInt64(0)
            var power = UInt64(1)
            for i in 1..<Int(headerSize) {
                msgSize += power * UInt64(header[i])
                power *= 0x100
            }
            
            guard let bPtr = buf.baseAddress else {
                throw MsgStreamError.badData
            }
            
            try readN(stream:self.stream, buf:bPtr, count:Int(msgSize))
            return msgSize
        }
    }
}
