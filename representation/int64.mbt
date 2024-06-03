/// Write bytes representation of an `Int64` by specified endianness into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn int64_into_bytes(v: Int64, endian: Endianness, target: Bytes, offset: Int) -> Unit {
  @assertion.assert_true(offset + 8 <= target.length()).map_err(fn (msg) -> Unit { abort(msg) }).unwrap()
  for bs = 0; bs < 8; bs = bs + 1 {
    let bd = endianness_index(bs, 8, endian)
    target[offset + bd] = v.lsr(bs * 8).land(0xFFL).to_byte()
  }
}

/// Write bytes representation of an `Int64` by little-endian into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn int64_into_bytes_le(v: Int64, target: Bytes, offset: Int) -> Unit {
  int64_into_bytes(v, Endianness::LittleEndian, target, offset)
}

/// Write bytes representation of an `Int64` by big-endian into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn int64_into_bytes_be(v: Int64, target: Bytes, offset: Int) -> Unit {
  int64_into_bytes(v, Endianness::BigEndian, target, offset)
}

test "int64_into_bytes(series)" {
  let cases = [
    (
      0xff_01_02_03_04_05_06_07_L, 
      0,
      Bytes::[0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc],
      Bytes::[0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0xff, 0xcc, 0xcc],
      Bytes::[0xff, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0xcc, 0xcc],
    ),
    (
      0x01_02_03_04_05_06_07_ff_L, 
      1, 
      Bytes::[0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa], 
      Bytes::[0xaa, 0xff, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0xaa], 
      Bytes::[0xaa, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0xff, 0xaa], 
    ),
    (
      0xd3_9c_33_c7_f8_17_5d_9c_L, 
      2, 
      Bytes::[0xdf, 0xfd, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf],
      Bytes::[0xdf, 0xfd, 0x9c, 0x5d, 0x17, 0xf8, 0xc7, 0x33, 0x9c, 0xd3],
      Bytes::[0xdf, 0xfd, 0xd3, 0x9c, 0x33, 0xc7, 0xf8, 0x17, 0x5d, 0x9c],
    ),
  ]

  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (input, pos, original, le_expected, be_expected) = cases[icase];
    let buffer = original.copy()
    int64_into_bytes(input, Endianness::LittleEndian, buffer, pos)
    test_bytes_eq(buffer, le_expected)?
    let buffer = original.copy()
    int64_into_bytes(input, Endianness::BigEndian, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
    let buffer = original.copy()
    int64_into_bytes(input, Endianness::NetworkEndian, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
    let buffer = original.copy()
    int64_into_bytes_le(input, buffer, pos)
    test_bytes_eq(buffer, le_expected)?
    let buffer = original.copy()
    int64_into_bytes_be(input, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
  }
}

/// Get bytes representation of an `Int64` by specified endianness.
pub fn int64_to_bytes(v: Int64, endian: Endianness) -> Bytes {
  let ret = Bytes::make(8)
  int64_into_bytes(v, endian, ret, 0)
  ret
}

/// Get bytes representation of an `Int64` by little-endian.
pub fn int64_to_bytes_le(v: Int64) -> Bytes {
  let ret = Bytes::make(8)
  int64_into_bytes(v, Endianness::LittleEndian, ret, 0)
  ret
}

/// Get bytes representation of an `Int64` by big-endian.
pub fn int64_to_bytes_be(v: Int64) -> Bytes {
  let ret = Bytes::make(8)
  int64_into_bytes(v, Endianness::BigEndian, ret, 0)
  ret
}

test "int64_to_bytes(series)" {
  let input = 0xff_01_02_03_04_05_06_07_L;
  let le_expected = Bytes::[0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0xff]
  let be_expected = Bytes::[0xff, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]
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
    r = r.lor(bytes[bs].to_int().land(0xff).to_int64().lsl(8 * bd))
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
  let input = Bytes::[0x83, 0xe7, 0x4c, 0xcb, 0x8e, 0x35, 0x1c, 0xc5, 0xa4, 0x4e]
  let cases = [
    (0, 0xc5_1c_35_8e_cb_4c_e7_83_L, 0x83_e7_4c_cb_8e_35_1c_c5_L), 
    (1, 0xa4_c5_1c_35_8e_cb_4c_e7_L, 0xe7_4c_cb_8e_35_1c_c5_a4_L), 
    (2, 0x4e_a4_c5_1c_35_8e_cb_4c_L, 0x4c_cb_8e_35_1c_c5_a4_4e_L),
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
