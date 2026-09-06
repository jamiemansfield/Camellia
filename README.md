# Camellia

Camellia is a small Swift library for reading and writing binary data. It provides a cursor-oriented `ByteReader` and an owning `ByteWriter` without introducing a larger serialization framework.

## Requirements

- Swift 6.3 or newer
- The experimental `Lifetimes` feature while the required lifetime syntax remains experimental

The package enables `Lifetimes` for the library and benchmark targets.

## ByteReader

Create a reader from a span and consume values relative to its current position:

```swift
import Camellia

let bytes: [UInt8] = [
    0x43,
    0x12, 0x34,
    0x78, 0x56, 0x34, 0x12,
]

var reader = ByteReader(bytes.span)

let marker = try reader.readU8()
let bigEndianValue = try reader.readU16(endian: .big)
let littleEndianValue = try reader.readU32(endian: .little)

print(marker)              // 67
print(bigEndianValue)      // 4660
print(littleEndianValue)   // 305419896
print(reader.isAtEnd)      // true
```

The reader exposes its cursor through `index`, together with `length`, `remaining`, `hasRemaining`, and `isAtEnd`.

### Peeking and expectations

Peeking does not move the cursor:

```swift
if reader.peekU8() == 0x43 {
    try reader.expectU8(0x43)
}
```

An expectation advances by one byte when it succeeds. EOF and mismatches throw `ByteReaderError`; a mismatch leaves the cursor unchanged.

### Borrowed byte ranges

`readBytes(count:)` is the consuming bulk-read operation:

```swift
let payload = try reader.readBytes(count: 16)
```

`remainingBytes` returns a non-consuming view from the cursor to the end of the input:

```swift
let unread = reader.remainingBytes
```

`slice(_:)` uses an absolute range from the beginning of the input and does not move the cursor:

```swift
let header = try reader.slice(0..<4)
```

All three APIs return borrowed `Span<UInt8>` values rather than allocating or copying arrays.

Because the reader and returned spans borrow their storage, keep the original contiguous storage alive and do not mutate it while those borrowed values are in use.

## ByteWriter

`ByteWriter` owns an array and appends values at the end:

```swift
import Camellia

var writer = ByteWriter(initialCapacity: 16)

writer.writeU8(0x43)
writer.writeI16(-1, endian: .big)
writer.writeU32(0x12345678, endian: .little)

let extra: [UInt8] = [0xaa, 0xbb]
writer.writeBytes(extra.span)

print(writer.count)
print(writer.bytes)
```

Signed reads and writes preserve the integer bit pattern. Integer operations support 16-, 32-, and 64-bit values in both little- and big-endian byte order.

## Errors

Reader operations use typed throws with `ByteReaderError`:

```swift
do {
    let value = try reader.readU64(endian: .big)
    print(value)
} catch let error {
    switch error {
    case .negativeCount(let count):
        print("Invalid count: \(count)")
    case .endOfInput(let requested, let remaining):
        print("Requested \(requested) bytes with \(remaining) remaining")
    case .byteMismatch(let expected, let actual):
        print("Expected \(expected), found \(actual)")
    case .invalidRange(let range, let length):
        print("Range \(range) is invalid for input length \(length)")
    }
}
```

Failed fixed-width reads and failed expectations do not partially advance the cursor.

## Development

Run the test suite with:

```sh
swift test
```

Run the benchmarks with:

```sh
swift package benchmark --target CamelliaBenchmarks
```

To save a baseline and compare future changes:

```sh
swift package \
    --allow-writing-to-directory .benchmarkBaselines \
    benchmark baseline update before

# Make changes, then compare the current implementation with the baseline.
swift package benchmark baseline compare before
```
