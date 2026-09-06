import Testing
@testable import Camellia

@Test func writesIntegersInBothByteOrders() {
    var writer = ByteWriter(initialCapacity: 14)
    writer.writeU16(0x1234, endian: .little)
    writer.writeU32(0x12345678, endian: .big)
    writer.writeU64(0x0123456789abcdef, endian: .little)

    #expect(writer.count == 14)
    #expect(writer.bytes == [
        0x34, 0x12, 0x12, 0x34, 0x56, 0x78,
        0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01,
    ])
}

@Test func writesSignedIntegerBitPatterns() {
    var writer = ByteWriter()
    writer.writeI8(-1)
    writer.writeI16(-2, endian: .big)
    writer.writeI32(.min, endian: .little)
    writer.writeI64(-0x0102030405060708, endian: .big)

    #expect(writer.bytes == [
        0xff,
        0xff, 0xfe,
        0x00, 0x00, 0x00, 0x80,
        0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf8, 0xf8,
    ])
}

@Test func writerAcceptsBorrowedBytes() {
    let source: [UInt8] = [2, 3, 4]
    var writer = ByteWriter()
    writer.writeU8(1)
    writer.writeBytes(source.span)

    #expect(writer.bytes == [1, 2, 3, 4])
}

@Test func writerOutputRoundTripsThroughReader() throws {
    var writer = ByteWriter()
    writer.writeU8(0xa5)
    writer.writeU16(0xbeef, endian: .big)
    writer.writeU32(0xdeadbeef, endian: .little)
    writer.writeU64(0x0123456789abcdef, endian: .big)
    writer.writeI8(-100)
    writer.writeI16(-12_345, endian: .little)
    writer.writeI32(-1_234_567_890, endian: .big)
    writer.writeI64(.min, endian: .little)

    var reader = ByteReader(writer.bytes.span)

    #expect(try reader.readU8() == 0xa5)
    #expect(try reader.readU16(endian: .big) == 0xbeef)
    #expect(try reader.readU32(endian: .little) == 0xdeadbeef)
    #expect(try reader.readU64(endian: .big) == 0x0123456789abcdef)
    #expect(try reader.readI8() == -100)
    #expect(try reader.readI16(endian: .little) == -12_345)
    #expect(try reader.readI32(endian: .big) == -1_234_567_890)
    #expect(try reader.readI64(endian: .little) == .min)

    let reachedEnd = reader.isAtEnd
    #expect(reachedEnd)
}
