extension ByteWriter {
    /// Appends the UTF-8 encoding of `value`.
    public mutating func writeUTF8(_ value: String) {
        bytes.append(contentsOf: value.utf8)
    }
}
