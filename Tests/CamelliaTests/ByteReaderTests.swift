import Testing
@testable import Camellia

@Test func lengthIsIndependentOfCursor() throws {
    let bytes: [UInt8] = [1, 2, 3, 4]
    var reader = ByteReader(bytes.span)

    #expect(reader.length == 4)

    try reader.advance(3)

    #expect(reader.length == 4)
    #expect(reader.remaining == 1)
}

@Test func remainingBytesTracksCursorWithoutConsuming() throws {
    let bytes: [UInt8] = [10, 20, 30]
    var reader = ByteReader(bytes.span)

    let initial = reader.remainingBytes
    #expect(initial.count == 3)
    #expect(initial[0] == 10)
    #expect(initial[1] == 20)
    #expect(initial[2] == 30)
    #expect(reader.index == 0)

    try reader.advance(2)

    let remaining = reader.remainingBytes
    #expect(remaining.count == 1)
    #expect(remaining[0] == 30)
    #expect(reader.index == 2)

    try reader.advance()

    let empty = reader.remainingBytes
    let isEmpty = empty.isEmpty
    #expect(isEmpty)
    #expect(reader.index == 3)
}

@Test func readsIntegersInBothByteOrders() throws {
    let bytes: [UInt8] = [
        0x34, 0x12,
        0x12, 0x34, 0x56, 0x78,
        0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01,
    ]
    var reader = ByteReader(bytes.span)

    #expect(try reader.readU16(endian: .little) == 0x1234)
    #expect(try reader.readU32(endian: .big) == 0x12345678)
    #expect(try reader.readU64(endian: .little) == 0x0123456789abcdef)

    let reachedEnd = reader.isAtEnd
    #expect(reachedEnd)
}

@Test func readsSignedIntegerBitPatterns() throws {
    let bytes: [UInt8] = [
        0xff,
        0xff, 0xfe,
        0x00, 0x00, 0x00, 0x80,
        0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf8, 0xf8,
    ]
    var reader = ByteReader(bytes.span)

    #expect(try reader.readI8() == -1)
    #expect(try reader.readI16(endian: .big) == -2)
    #expect(try reader.readI32(endian: .little) == .min)
    #expect(try reader.readI64(endian: .big) == -0x0102030405060708)
}

@Test func reportsEOFWithoutMovingCursor() throws {
    let bytes: [UInt8] = [1, 2, 3]
    var reader = ByteReader(bytes.span)

    #expect(throws: ByteReaderError.endOfInput(requested: 4, remaining: 3)) {
        try reader.readU32(endian: .big)
    }
    #expect(reader.index == 0)

    try reader.advance(2)

    #expect(throws: ByteReaderError.endOfInput(requested: 2, remaining: 1)) {
        try reader.advance(2)
    }
    #expect(reader.index == 2)

    _ = try reader.readU8()

    #expect(throws: ByteReaderError.endOfInput(requested: 1, remaining: 0)) {
        try reader.readU8()
    }
}

@Test func handlesZeroAndNegativeCounts() throws {
    let bytes: [UInt8] = [7]
    var reader = ByteReader(bytes.span)

    try reader.advance(0)
    let empty = try reader.readBytes(count: 0)
    let isEmpty = empty.isEmpty

    #expect(isEmpty)
    #expect(reader.index == 0)
    #expect(throws: ByteReaderError.negativeCount(-1)) { try reader.advance(-1) }
    #expect(throws: ByteReaderError.negativeCount(-2)) {
        _ = try reader.readBytes(count: -2)
    }
}

@Test func peeksUsingRelativeOffsets() throws {
    let bytes: [UInt8] = [10, 20, 30]
    var reader = ByteReader(bytes.span)

    #expect(reader.peekU8() == 10)
    #expect(reader.peekU8(offset: 2) == 30)
    #expect(reader.peekU8(offset: -1) == nil)
    #expect(reader.peekU8(offset: 3) == nil)
    #expect(reader.peekU8(offset: .max) == nil)

    try reader.advance()

    #expect(reader.peekU8() == 20)
}

@Test func peeksSignedBytesAndRejectsInvalidOffsets() throws {
    let bytes: [UInt8] = [0x7f, 0x80, 0xff]
    var reader = ByteReader(bytes.span)

    #expect(reader.peekI8() == 127)
    #expect(reader.peekI8(offset: 1) == -128)
    #expect(reader.peekI8(offset: 2) == -1)
    #expect(reader.peekI8(offset: -1) == nil)
    #expect(reader.peekI8(offset: 3) == nil)
    #expect(reader.peekI8(offset: .max) == nil)

    try reader.advance(2)

    #expect(reader.peekI8() == -1)
    #expect(reader.peekI8(offset: 1) == nil)
}

@Test func expectsUnsignedByteWithoutAdvancingOnMismatch() throws {
    let bytes: [UInt8] = [0x12, 0x34]
    var reader = ByteReader(bytes.span)

    try reader.expectU8(0x12)

    #expect(reader.index == 1)
    #expect(throws: ByteReaderError.byteMismatch(expected: 0xff, actual: 0x34)) {
        try reader.expectU8(0xff)
    }
    #expect(reader.index == 1)

    try reader.expectU8(0x34)

    #expect(reader.index == 2)
}

@Test func expectsSignedByteWithoutAdvancingOnMismatch() throws {
    let bytes: [UInt8] = [0xff, 0x80]
    var reader = ByteReader(bytes.span)

    try reader.expectI8(-1)

    #expect(reader.index == 1)
    #expect(throws: ByteReaderError.byteMismatch(expected: 0x7f, actual: 0x80)) {
        try reader.expectI8(127)
    }
    #expect(reader.index == 1)

    try reader.expectI8(-128)

    #expect(reader.index == 2)
}

@Test func expectationsReportEOF() throws {
    let bytes: [UInt8] = []
    var reader = ByteReader(bytes.span)

    #expect(throws: ByteReaderError.endOfInput(requested: 1, remaining: 0)) {
        try reader.expectU8(0)
    }
    #expect(throws: ByteReaderError.endOfInput(requested: 1, remaining: 0)) {
        try reader.expectI8(0)
    }
    #expect(reader.index == 0)
}

@Test func readBytesReturnsBorrowedSliceAndAdvances() throws {
    let bytes: [UInt8] = [1, 2, 3, 4]
    var reader = ByteReader(bytes.span)

    try reader.advance()
    let slice = try reader.readBytes(count: 2)

    #expect(slice.count == 2)
    #expect(slice[0] == 2)
    #expect(slice[1] == 3)
    #expect(reader.index == 3)
    #expect(reader.remaining == 1)

    let hasRemaining = reader.hasRemaining
    #expect(hasRemaining)
}

@Test func slicesAbsoluteRangesWithoutMovingCursor() throws {
    let bytes: [UInt8] = [10, 20, 30, 40, 50]
    var reader = ByteReader(bytes.span)
    try reader.advance(2)

    let beforeCursor = try reader.slice(0..<2)
    #expect(beforeCursor.count == 2)
    #expect(beforeCursor[0] == 10)
    #expect(beforeCursor[1] == 20)

    let afterCursor = try reader.slice(3..<5)
    #expect(afterCursor.count == 2)
    #expect(afterCursor[0] == 40)
    #expect(afterCursor[1] == 50)
    #expect(reader.index == 2)
}

@Test func rejectsInvalidAbsoluteSlices() {
    let bytes: [UInt8] = [1, 2, 3]
    let reader = ByteReader(bytes.span)

    #expect(throws: ByteReaderError.invalidRange(-1..<1, length: 3)) {
        _ = try reader.slice(-1..<1)
    }
    #expect(throws: ByteReaderError.invalidRange(1..<4, length: 3)) {
        _ = try reader.slice(1..<4)
    }
}
