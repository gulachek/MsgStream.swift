//
//  StreamUtils.swift
//
//
//  Created by Nicholas Gulachek on 7/20/24.
//

import Foundation

internal func writeN(stream: OutputStream, buf: UnsafeRawPointer, count: Int) throws -> Void {
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

internal func readN(stream: InputStream, buf: UnsafeMutableRawPointer, count: Int) throws -> Void {
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
