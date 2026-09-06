public struct ByteReader: ~Escapable {
    private let bytes: Span<UInt8>
    public private(set) var index = 0

    @_lifetime(copy source)
    public init(_ source: Span<UInt8>) {
        self.bytes = source
    }

    public var length: Int {
        bytes.count
    }

    public var remaining: Int {
        bytes.count - index
    }

    public var remainingBytes: Span<UInt8> {
        @_lifetime(copy self)
        get {
            bytes.extracting(index..<bytes.count)
        }
    }

    public var hasRemaining: Bool {
        remaining > 0
    }

    public var isAtEnd: Bool {
        remaining == 0
    }

    public mutating func advance(_ count: Int = 1) throws(ByteReaderError) {
        guard count >= 0 else {
            throw ByteReaderError.negativeCount(count)
        }

        guard count <= remaining else {
            throw ByteReaderError.endOfInput(
                requested: count,
                remaining: remaining
            )
        }

        index += count
    }

    public func peekU8(offset: Int = 0) -> UInt8? {
        guard offset >= 0, offset < remaining else {
            return nil
        }

        return bytes[index + offset]
    }

    public func peekI8(offset: Int = 0) -> Int8? {
        guard let value = peekU8(offset: offset) else {
            return nil
        }

        return Int8(bitPattern: value)
    }

    public mutating func expectU8(_ expected: UInt8) throws(ByteReaderError) {
        guard let actual = peekU8() else {
            throw ByteReaderError.endOfInput(requested: 1, remaining: 0)
        }

        guard actual == expected else {
            throw ByteReaderError.byteMismatch(
                expected: expected,
                actual: actual
            )
        }

        try advance()
    }

    public mutating func expectI8(_ expected: Int8) throws(ByteReaderError) {
        guard let actual = peekI8() else {
            throw ByteReaderError.endOfInput(requested: 1, remaining: 0)
        }

        guard actual == expected else {
            throw ByteReaderError.byteMismatch(
                expected: UInt8(bitPattern: expected),
                actual: UInt8(bitPattern: actual)
            )
        }

        try advance()
    }

    public mutating func readU8() throws(ByteReaderError) -> UInt8 {
        guard hasRemaining else {
            throw ByteReaderError.endOfInput(requested: 1, remaining: 0)
        }

        let value = bytes[index]
        index += 1

        return value
    }

    public mutating func readI8() throws(ByteReaderError) -> Int8 {
        Int8(bitPattern: try readU8())
    }

    public mutating func readU16(endian: Endianness) throws(ByteReaderError) -> UInt16 {
        let byteCount = MemoryLayout<UInt16>.size
        guard byteCount <= remaining else {
            throw ByteReaderError.endOfInput(
                requested: byteCount,
                remaining: remaining
            )
        }

        let a = UInt16(bytes[index])
        let b = UInt16(bytes[index + 1])
        let value: UInt16

        switch endian {
        case .little:
            value = a | (b << 8)
        case .big:
            value = (a << 8) | b
        }

        index += byteCount

        return value
    }

    public mutating func readI16(endian: Endianness) throws(ByteReaderError) -> Int16 {
        Int16(bitPattern: try readU16(endian: endian))
    }

    public mutating func readU32(endian: Endianness) throws(ByteReaderError) -> UInt32 {
        let byteCount = MemoryLayout<UInt32>.size
        guard byteCount <= remaining else {
            throw ByteReaderError.endOfInput(
                requested: byteCount,
                remaining: remaining
            )
        }

        let a = UInt32(bytes[index])
        let b = UInt32(bytes[index + 1])
        let c = UInt32(bytes[index + 2])
        let d = UInt32(bytes[index + 3])
        let value: UInt32

        switch endian {
        case .little:
            value = a | (b << 8) | (c << 16) | (d << 24)
        case .big:
            value = (a << 24) | (b << 16) | (c << 8) | d
        }

        index += byteCount

        return value
    }

    public mutating func readI32(endian: Endianness) throws(ByteReaderError) -> Int32 {
        Int32(bitPattern: try readU32(endian: endian))
    }

    public mutating func readU64(endian: Endianness) throws(ByteReaderError) -> UInt64 {
        let byteCount = MemoryLayout<UInt64>.size
        guard byteCount <= remaining else {
            throw ByteReaderError.endOfInput(
                requested: byteCount,
                remaining: remaining
            )
        }

        let a = UInt64(bytes[index])
        let b = UInt64(bytes[index + 1])
        let c = UInt64(bytes[index + 2])
        let d = UInt64(bytes[index + 3])
        let e = UInt64(bytes[index + 4])
        let f = UInt64(bytes[index + 5])
        let g = UInt64(bytes[index + 6])
        let h = UInt64(bytes[index + 7])
        let value: UInt64

        switch endian {
        case .little:
            value = a
                | (b << 8)
                | (c << 16)
                | (d << 24)
                | (e << 32)
                | (f << 40)
                | (g << 48)
                | (h << 56)
        case .big:
            value = (a << 56)
                | (b << 48)
                | (c << 40)
                | (d << 32)
                | (e << 24)
                | (f << 16)
                | (g << 8)
                | h
        }

        index += byteCount

        return value
    }

    public mutating func readI64(endian: Endianness) throws(ByteReaderError) -> Int64 {
        Int64(bitPattern: try readU64(endian: endian))
    }

    @_lifetime(copy self)
    public mutating func readBytes(count: Int) throws(ByteReaderError) -> Span<UInt8> {
        guard count >= 0 else {
            throw ByteReaderError.negativeCount(count)
        }

        guard count <= remaining else {
            throw ByteReaderError.endOfInput(
                requested: count,
                remaining: remaining
            )
        }

        let start = index
        index += count

        return bytes.extracting(start..<index)
    }

    @_lifetime(copy self)
    public func slice(_ range: Range<Int>) throws(ByteReaderError) -> Span<UInt8> {
        guard range.lowerBound >= 0,
              range.upperBound <= bytes.count
        else {
            throw ByteReaderError.invalidRange(
                range,
                length: bytes.count
            )
        }

        return bytes.extracting(range)
    }
}
