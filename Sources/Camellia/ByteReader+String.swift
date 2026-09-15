extension ByteReader {
    /// Reads `count` bytes and decodes them as UTF-8.
    public mutating func readUTF8(count: Int) throws(ByteReaderError) -> String {
        let bytes = try readBytes(count: count)
        return bytes.withUnsafeBufferPointer { buffer in
            String(decoding: buffer, as: UTF8.self)
        }
    }

    /// Consumes `expected` when its UTF-8 encoding is next in the input.
    /// Returns `false` and leaves the cursor unchanged otherwise.
    public mutating func match(_ expected: String) -> Bool {
        let encoded = expected.utf8
        guard encoded.count <= remaining else { return false }

        var offset = 0
        for byte in encoded {
            guard bytes[index + offset] == byte else { return false }
            offset += 1
        }

        index += offset
        return true
    }

    /// Requires `expected` to be next in the input and consumes it.
    public mutating func expect(_ expected: String) throws(ByteReaderError) {
        let encoded = expected.utf8
        let count = encoded.count

        guard count <= remaining else {
            throw .endOfInput(requested: count, remaining: remaining)
        }

        var offset = 0
        for byte in encoded {
            let actual = bytes[index + offset]
            guard actual == byte else {
                throw .byteMismatch(expected: byte, actual: actual)
            }
            offset += 1
        }

        index += offset
    }
}
