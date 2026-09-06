public enum ByteReaderError: Error, Equatable, Sendable {
    case negativeCount(Int)
    case endOfInput(requested: Int, remaining: Int)
    case byteMismatch(expected: UInt8, actual: UInt8)
    case invalidRange(Range<Int>, length: Int)
}
