/// Get bytes representation of an `Int` by specified endianness.
pub fn int_to_bytes(v: Int, endian: Endianness) -> Bytes {
  let ret = Bytes::make(4, 0)
  for bs = 0; bs < 4; bs = bs + 1 {
    let bd = endianness_index(bs, 4, endian)
    ret[bd] = v.lsr(bs * 8).land(0xFF)
  }
  ret
}

/// Get bytes representation of an `Int` by little-endian.
pub fn int_to_bytes_le(v: Int) -> Bytes {
  int_to_bytes(v, Endianness::LittleEndian)
}

/// Get bytes representation of an `Int` by big-endian.
pub fn int_to_bytes_be(v: Int) -> Bytes {
  int_to_bytes(v, Endianness::BigEndian)
}

test "int_to_bytes(series)" {
  let input = 0xff0b0c0d
  let le_expected = Bytes::make(4, 0)
  le_expected[0] = b'\x0d'.to_int()
  le_expected[1] = b'\x0c'.to_int()
  le_expected[2] = b'\x0b'.to_int()
  le_expected[3] = b'\xff'.to_int()
  let be_expected = Bytes::make(4, 0)
  be_expected[0] = le_expected[3]
  be_expected[1] = le_expected[2]
  be_expected[2] = le_expected[1]
  be_expected[3] = le_expected[0]
  test_bytes_eq(int_to_bytes(input, Endianness::LittleEndian), le_expected)?
  test_bytes_eq(int_to_bytes(input, Endianness::BigEndian), be_expected)?
  test_bytes_eq(int_to_bytes(input, Endianness::NetworkEndian), be_expected)?
  test_bytes_eq(int_to_bytes_le(input), le_expected)?
  test_bytes_eq(int_to_bytes_be(input), be_expected)?
}

/// Extract an `Int` from certain position of `Bytes` by specified endianness.
/// 
/// # Panics
/// 
/// 4 bytes of data are required from offset position. Panics when insufficient.
pub fn int_from_bytes(bytes: Bytes, offset: Int, endian: Endianness) -> Int {
  @assertion.assert_true(offset + 4 <= bytes.length()).map_err(fn (msg) -> Unit { abort(msg) }).unwrap()
  let mut r = 0
  for bd = 0; bd < 4; bd = bd + 1 {
    let bs = offset + endianness_index(bd, 4, endian)
    r = r.lor(bytes[bs].land(0xff).lsl(8 * bd))
  }
  r
}

/// Extract an `Int` from certain position of `Bytes` by little-endian.
/// 
/// # Panics
/// 
/// 4 bytes of data are required from offset position. Panics when insufficient.
pub fn int_le_from_bytes(bytes: Bytes, offset: Int) -> Int {
  int_from_bytes(bytes, offset, Endianness::LittleEndian)
}

/// Extract an `Int` from certain position of `Bytes` by big-endian.
/// 
/// # Panics
/// 
/// 4 bytes of data are required from offset position. Panics when insufficient.
pub fn int_be_from_bytes(bytes: Bytes, offset: Int) -> Int {
  int_from_bytes(bytes, offset, Endianness::BigEndian)
}

test "int_from_bytes(series)" {
  let input = Bytes::make(6, 0)
  input[0] = b'\x7c'.to_int()
  input[1] = b'\x47'.to_int()
  input[2] = b'\x18'.to_int()
  input[3] = b'\x49'.to_int()
  input[4] = b'\xff'.to_int()
  input[5] = b'\x6c'.to_int()
  let cases = [
    (0, 0x4918477c, 0x7c471849), (1, 0xff491847, 0x471849ff), (2, 0x6cff4918, 0x1849ff6c),
  ]
  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (pos, le_expected, be_expected) = cases[icase];
    @assertion.assert_eq(int_from_bytes(input, pos, Endianness::LittleEndian), le_expected)?
    @assertion.assert_eq(int_le_from_bytes(input, pos), le_expected)?
    @assertion.assert_eq(int_from_bytes(input, pos, Endianness::BigEndian), be_expected)?
    @assertion.assert_eq(int_from_bytes(input, pos, Endianness::NetworkEndian), be_expected)?
    @assertion.assert_eq(int_be_from_bytes(input, pos), be_expected)?
  }
}
