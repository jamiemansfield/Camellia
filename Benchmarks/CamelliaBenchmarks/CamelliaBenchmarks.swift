import Benchmark
import Camellia

private let byteCount = 1 << 20
private let u16Count = byteCount / MemoryLayout<UInt16>.size
private let u32Count = byteCount / MemoryLayout<UInt32>.size
private let u64Count = byteCount / MemoryLayout<UInt64>.size
private let input = (0..<byteCount).map { index in
    UInt8(truncatingIfNeeded: index &* 31 &+ 17)
}
private let input16 = Array(input.prefix(16))
private let input256 = Array(input.prefix(256))
private let input4096 = Array(input.prefix(4096))

let benchmarks: @Sendable () -> Void = {
    Benchmark("ByteReader.readU8 (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var reader = ByteReader(input.span)
            var checksum: UInt64 = 0

            while reader.hasRemaining {
                checksum &+= UInt64(try! reader.readU8())
            }

            blackHole(checksum)
        }
    }

    Benchmark("ByteReader.readU16 little (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var reader = ByteReader(input.span)
            var checksum: UInt64 = 0

            while reader.hasRemaining {
                checksum &+= UInt64(try! reader.readU16(endian: .little))
            }

            blackHole(checksum)
        }
    }

    Benchmark("ByteReader.readU16 big (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var reader = ByteReader(input.span)
            var checksum: UInt64 = 0

            while reader.hasRemaining {
                checksum &+= UInt64(try! reader.readU16(endian: .big))
            }

            blackHole(checksum)
        }
    }

    Benchmark("ByteReader.readU32 little (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var reader = ByteReader(input.span)
            var checksum: UInt64 = 0

            while reader.hasRemaining {
                checksum &+= UInt64(try! reader.readU32(endian: .little))
            }

            blackHole(checksum)
        }
    }

    Benchmark("ByteReader.readU32 big (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var reader = ByteReader(input.span)
            var checksum: UInt64 = 0

            while reader.hasRemaining {
                checksum &+= UInt64(try! reader.readU32(endian: .big))
            }

            blackHole(checksum)
        }
    }

    Benchmark("ByteReader.readU64 little (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var reader = ByteReader(input.span)
            var checksum: UInt64 = 0

            while reader.hasRemaining {
                checksum &+= try! reader.readU64(endian: .little)
            }

            blackHole(checksum)
        }
    }

    Benchmark("ByteReader.readU64 big (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var reader = ByteReader(input.span)
            var checksum: UInt64 = 0

            while reader.hasRemaining {
                checksum &+= try! reader.readU64(endian: .big)
            }

            blackHole(checksum)
        }
    }

    Benchmark("ByteReader.readBytes(256) (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var reader = ByteReader(input.span)
            var checksum: UInt64 = 0

            while reader.hasRemaining {
                let bytes = try! reader.readBytes(count: 256)
                checksum &+= UInt64(bytes[0])
                checksum &+= UInt64(bytes[255])
            }

            blackHole(checksum)
        }
    }

    Benchmark("ByteWriter.writeU8 reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<byteCount {
                writer.writeU8(0xa5)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeU8 growing (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter()

            for _ in 0..<byteCount {
                writer.writeU8(0xa5)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeU16 little (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<u16Count {
                writer.writeU16(0xa5a5, endian: .little)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeU16 big (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<u16Count {
                writer.writeU16(0xa5a5, endian: .big)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeU32 little (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<u32Count {
                writer.writeU32(0xa5a5a5a5, endian: .little)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeU32 big (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<u32Count {
                writer.writeU32(0xa5a5a5a5, endian: .big)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeU64 little (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<u64Count {
                writer.writeU64(0xa5a5a5a5a5a5a5a5, endian: .little)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeU64 big (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<u64Count {
                writer.writeU64(0xa5a5a5a5a5a5a5a5, endian: .big)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes single reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)
            writer.writeBytes(input.span)

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes single growing (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter()
            writer.writeBytes(input.span)

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes chunks of 16 reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<(byteCount / input16.count) {
                writer.writeBytes(input16.span)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes chunks of 256 reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<(byteCount / input256.count) {
                writer.writeBytes(input256.span)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes chunks of 4096 reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<(byteCount / input4096.count) {
                writer.writeBytes(input4096.span)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes Array single reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)
            writer.writeBytes(input)

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes Array single growing (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter()
            writer.writeBytes(input)

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes Array chunks of 16 reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<(byteCount / input16.count) {
                writer.writeBytes(input16)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes Array chunks of 256 reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<(byteCount / input256.count) {
                writer.writeBytes(input256)
            }

            blackHole(writer.bytes)
        }
    }

    Benchmark("ByteWriter.writeBytes Array chunks of 4096 reserved (1 MiB)") { benchmark in
        for _ in benchmark.scaledIterations {
            var writer = ByteWriter(initialCapacity: byteCount)

            for _ in 0..<(byteCount / input4096.count) {
                writer.writeBytes(input4096)
            }

            blackHole(writer.bytes)
        }
    }
}
