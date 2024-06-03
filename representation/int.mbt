/// Write bytes representation of an `Int` by specified endianness into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 4 bytes of data are required from offset position. Panics when insufficient.
pub fn int_into_bytes(v: Int, endian: Endianness, target: Bytes, offset: Int) -> Unit {
  @assertion.assert_true(offset + 4 <= target.length()).map_err(fn (msg) -> Unit { abort(msg) }).unwrap()
  for bs = 0; bs < 4; bs = bs + 1 {
    let bd = endianness_index(bs, 4, endian)
    target[offset + bd] = v.lsr(bs * 8).land(0xFF).to_byte()
  }
}

/// Write bytes representation of an `Int` by little-endian into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 4 bytes of data are required from offset position. Panics when insufficient.
pub fn int_into_bytes_le(v: Int, target: Bytes, offset: Int) -> Unit {
  int_into_bytes(v, Endianness::LittleEndian, target, offset)
}

/// Write bytes representation of an `Int` by big-endian into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 4 bytes of data are required from offset position. Panics when insufficient.
pub fn int_into_bytes_be(v: Int, target: Bytes, offset: Int) -> Unit {
  int_into_bytes(v, Endianness::BigEndian, target, offset)
}

test "int_into_bytes(series)" {
  let cases = [
    (
      0x07_06_05_04, 
      0, 
      Bytes::[0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc], 
      Bytes::[0x04, 0x05, 0x06, 0x07, 0xcc, 0xcc], 
      Bytes::[0x07, 0x06, 0x05, 0x04, 0xcc, 0xcc],
    ),
    (
      0xff_0b_0c_0d, 
      1, 
      Bytes::[0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa], 
      Bytes::[0xaa, 0x0d, 0x0c, 0x0b, 0xff, 0xaa], 
      Bytes::[0xaa, 0xff, 0x0b, 0x0c, 0x0d, 0xaa],
    ),
    (
      0x44_33_22_11, 
      2, 
      Bytes::[0xdf, 0xfd, 0xdf, 0xdf, 0xdf, 0xdf], 
      Bytes::[0xdf, 0xfd, 0x11, 0x22, 0x33, 0x44], 
      Bytes::[0xdf, 0xfd, 0x44, 0x33, 0x22, 0x11],
    ),
  ]

  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (input, pos, original, le_expected, be_expected) = cases[icase];

    let buffer = original.copy()
    int_into_bytes(input, Endianness::LittleEndian, buffer, pos)
    test_bytes_eq(buffer, le_expected)?
    let buffer = original.copy()
    int_into_bytes(input, Endianness::BigEndian, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
    let buffer = original.copy()
    int_into_bytes(input, Endianness::NetworkEndian, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
    let buffer = original.copy()
    int_into_bytes_le(input, buffer, pos)
    test_bytes_eq(buffer, le_expected)?
    let buffer = original.copy()
    int_into_bytes_be(input, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
  }
}

/// Get bytes representation of an `Int` by specified endianness.
pub fn int_to_bytes(v: Int, endian: Endianness) -> Bytes {
  let ret = Bytes::make(4)
  int_into_bytes(v, endian, ret, 0)
  ret
}

/// Get bytes representation of an `Int` by little-endian.
pub fn int_to_bytes_le(v: Int) -> Bytes {
  let ret = Bytes::make(4)
  int_into_bytes(v, Endianness::LittleEndian, ret, 0)
  ret
}

/// Get bytes representation of an `Int` by big-endian.
pub fn int_to_bytes_be(v: Int) -> Bytes {
  let ret = Bytes::make(4)
  int_into_bytes(v, Endianness::BigEndian, ret, 0)
  ret
}

test "int_to_bytes(series)" {
  let input = 0xff_0b_0c_0d
  let le_expected = Bytes::[0x0d, 0x0c, 0x0b, 0xff]
  let be_expected = Bytes::[0xff, 0x0b, 0x0c, 0x0d]
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
    r = r.lor(bytes[bs].to_int().land(0xff).lsl(8 * bd))
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
  let input = Bytes::[0x7c, 0x47, 0x18, 0x49, 0xff, 0x6c]
  let cases = [
    (0, 0x49_18_47_7c, 0x7c_47_18_49), (1, 0xff_49_18_47, 0x47_18_49_ff), (2, 0x6c_ff_49_18, 0x18_49_ff_6c),
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
