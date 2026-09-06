public struct ByteWriter: Sendable {
    public private(set) var bytes: [UInt8]

    public var count: Int {
        bytes.count
    }

    public init(initialCapacity: Int = 0) {
        precondition(initialCapacity >= 0, "Initial capacity must not be negative")

        bytes = []
        bytes.reserveCapacity(initialCapacity)
    }

    public mutating func writeU8(_ value: UInt8) {
        bytes.append(value)
    }

    public mutating func writeI8(_ value: Int8) {
        writeU8(UInt8(bitPattern: value))
    }

    public mutating func writeU16(_ value: UInt16, endian: Endianness) {
        writeInteger(value, endian: endian)
    }

    public mutating func writeI16(_ value: Int16, endian: Endianness) {
        writeU16(UInt16(bitPattern: value), endian: endian)
    }

    public mutating func writeU32(_ value: UInt32, endian: Endianness) {
        writeInteger(value, endian: endian)
    }

    public mutating func writeI32(_ value: Int32, endian: Endianness) {
        writeU32(UInt32(bitPattern: value), endian: endian)
    }

    public mutating func writeU64(_ value: UInt64, endian: Endianness) {
        writeInteger(value, endian: endian)
    }

    public mutating func writeI64(_ value: Int64, endian: Endianness) {
        writeU64(UInt64(bitPattern: value), endian: endian)
    }

    public mutating func writeBytes(_ source: Span<UInt8>) {
        bytes.reserveCapacity(bytes.count + source.count)

        for index in source.indices {
            bytes.append(source[index])
        }
    }

    private mutating func writeInteger<T: FixedWidthInteger>(
        _ value: T,
        endian: Endianness
    ) {
        let byteCount = MemoryLayout<T>.size
        bytes.reserveCapacity(bytes.count + byteCount)

        switch endian {
        case .little:
            for shift in 0..<byteCount {
                bytes.append(UInt8(truncatingIfNeeded: value >> (shift * 8)))
            }
        case .big:
            for offset in 0..<byteCount {
                let shift = (byteCount - 1 - offset) * 8
                bytes.append(UInt8(truncatingIfNeeded: value >> shift))
            }
        }
    }
}
