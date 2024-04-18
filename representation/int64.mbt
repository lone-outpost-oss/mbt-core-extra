/// Get bytes representation of an `Int64` by specified endianness.
pub fn int64_to_bytes(v: Int64, endian: Endianness) -> Bytes {
  let ret = Bytes::make(8, 0)
  for bs = 0; bs < 8; bs = bs + 1 {
    let bd = endianness_index(bs, 8, endian)
    ret[bd] = v.lsr(bs * 8).land(0xFFL).to_int()
  }
  ret
}

/// Get bytes representation of an `Int64` by little-endian.
pub fn int64_to_bytes_le(v: Int64) -> Bytes {
  int64_to_bytes(v, Endianness::LittleEndian)
}

/// Get bytes representation of an `Int64` by big-endian.
pub fn int64_to_bytes_be(v: Int64) -> Bytes {
  int64_to_bytes(v, Endianness::BigEndian)
}

test "int64_to_bytes(series)" {
  let input = 0xff01020304050607L;
  let le_expected = Bytes::make(8, 0)
  le_expected[0] = b'\x07'.to_int()
  le_expected[1] = b'\x06'.to_int()
  le_expected[2] = b'\x05'.to_int()
  le_expected[3] = b'\x04'.to_int()
  le_expected[4] = b'\x03'.to_int()
  le_expected[5] = b'\x02'.to_int()
  le_expected[6] = b'\x01'.to_int()
  le_expected[7] = b'\xff'.to_int()
  let be_expected = Bytes::make(8, 0)
  be_expected[0] = le_expected[7]
  be_expected[1] = le_expected[6]
  be_expected[2] = le_expected[5]
  be_expected[3] = le_expected[4]
  be_expected[4] = le_expected[3]
  be_expected[5] = le_expected[2]
  be_expected[6] = le_expected[1]
  be_expected[7] = le_expected[0]
  test_bytes_eq(int64_to_bytes(input, Endianness::LittleEndian), le_expected)?
  test_bytes_eq(int64_to_bytes(input, Endianness::BigEndian), be_expected)?
  test_bytes_eq(int64_to_bytes(input, Endianness::NetworkEndian), be_expected)?
  test_bytes_eq(int64_to_bytes_le(input), le_expected)?
  test_bytes_eq(int64_to_bytes_be(input), be_expected)?
}

/// Extract an `Int64` from certain position of `Bytes` by specified endianness.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn int64_from_bytes(bytes: Bytes, offset: Int, endian: Endianness) -> Int64 {
  @assertion.assert_true(offset + 8 <= bytes.length()).map_err(fn (msg) -> Unit { abort(msg) }).unwrap()
  let mut r = 0L
  for bd = 0; bd < 8; bd = bd + 1 {
    let bs = offset + endianness_index(bd, 8, endian)
    r = r.lor(bytes[bs].land(0xff).to_int64().lsl(8 * bd))
  }
  r
}

/// Extract an `Int64` from certain position of `Bytes` by little-endian.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn int64_le_from_bytes(bytes: Bytes, offset: Int) -> Int64 {
  int64_from_bytes(bytes, offset, Endianness::LittleEndian)
}

/// Extract an `Int64` from certain position of `Bytes` by big-endian.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn int64_be_from_bytes(bytes: Bytes, offset: Int) -> Int64 {
  int64_from_bytes(bytes, offset, Endianness::BigEndian)
}

test "int64_from_bytes(series)" {
  let input = Bytes::make(10, 0)
  input[0] = b'\x83'.to_int()
  input[1] = b'\xe7'.to_int()
  input[2] = b'\x4c'.to_int()
  input[3] = b'\xcb'.to_int()
  input[4] = b'\x8e'.to_int()
  input[5] = b'\x35'.to_int()
  input[6] = b'\x1c'.to_int()
  input[7] = b'\xc5'.to_int()
  input[8] = b'\xa4'.to_int()
  input[9] = b'\x4e'.to_int()
  let cases = [
    (0, 0xc51c358ecb4ce783L, 0x83e74ccb8e351cc5L), 
    (1, 0xa4c51c358ecb4ce7L, 0xe74ccb8e351cc5a4L), 
    (2, 0x4ea4c51c358ecb4cL, 0x4ccb8e351cc5a44eL),
  ]
  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (pos, le_expected, be_expected) = cases[icase];
    @assertion.assert_eq(int64_from_bytes(input, pos, Endianness::LittleEndian), le_expected)?
    @assertion.assert_eq(int64_le_from_bytes(input, pos), le_expected)?
    @assertion.assert_eq(int64_from_bytes(input, pos, Endianness::BigEndian), be_expected)?
    @assertion.assert_eq(int64_from_bytes(input, pos, Endianness::NetworkEndian), be_expected)?
    @assertion.assert_eq(int64_be_from_bytes(input, pos), be_expected)?
  }
}
