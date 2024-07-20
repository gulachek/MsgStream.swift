import Foundation

// The Swift Programming Language
// https://docs.swift.org/swift-book


public protocol MsgHasMutableBytes {
    mutating func withUnsafeMutableBytes<ResultType>(_ body: (UnsafeMutableRawBufferPointer) throws -> ResultType) rethrows -> ResultType
}

public protocol MsgHasBytes {
    func withUnsafeBytes<ResultType>(_ body: (UnsafeRawBufferPointer) throws -> ResultType) rethrows -> ResultType
}

extension Data : MsgHasBytes, MsgHasMutableBytes {}
extension [UInt8] : MsgHasBytes, MsgHasMutableBytes {}
extension ContiguousArray<UInt8> : MsgHasBytes, MsgHasMutableBytes {}
extension ArraySlice<UInt8> : MsgHasBytes, MsgHasMutableBytes {}

public protocol MsgSender {
    func send<T: MsgHasBytes>(_ data: T, recvBufSize: Int) throws -> Void;
}

public protocol MsgReceiver {
    func receive<T: MsgHasMutableBytes>(_ data: inout T) throws -> UInt64;
}

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

public struct MsgStreamHeader {
    private var _buf: [UInt8]
    
    var buf: ContiguousBytes {
        get { self._buf }
    }
    
    init(bufSize: UInt64) {
        let count = Self.size(forMsgBufSize:bufSize)
        self._buf = [UInt8].init(repeating:0, count:Int(count))
        self._buf[0] = count
    }
    
    public static func size(forMsgBufSize bufSize: UInt64) -> UInt8 {
        return bytesToStore(bufSize) + 1;
    }
}

public class StreamMsgSender : MsgSender {
    let stream: OutputStream;
    
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
    
    private func pumpErr() throws -> Void {
        if let err = self.stream.streamError {
            throw err
        }
    }
    
    public func open() throws -> Void {
        self.stream.open()
        try self.pumpErr()
    }
    
    public func close() throws -> Void {
        self.stream.close()
        try self.pumpErr()
    }
}

public class StreamMsgReceiver : MsgReceiver {
    public let stream: InputStream
    
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

private func writeN(stream: OutputStream, buf: UnsafeRawPointer, count: Int) throws -> Void {
    var writeBuf = buf
    var nLeft = count
    while nLeft > 0 {
        let n = stream.write(writeBuf, maxLength: nLeft)
        if (n < 0) {
            throw MsgStreamError.writeFailed(stream.streamError)
        }
        
        nLeft -= n
        writeBuf = writeBuf.advanced(by:n)
    }
}

private func readN(stream: InputStream, buf: UnsafeMutableRawPointer, count: Int) throws -> Void {
    var readBuf = buf
    var nLeft = count
    while nLeft > 0 {
        let n = stream.read(readBuf, maxLength:nLeft)
        if (n < 0) {
            throw MsgStreamError.readFailed(stream.streamError)
        } else if (n == 0) {
            throw MsgStreamError.badData
        }
        
        nLeft -= n
        readBuf = readBuf.advanced(by:n)
    }
}
