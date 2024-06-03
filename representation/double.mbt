/// Write bytes representation of an `Double` by specified endianness into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn double_into_bytes(v: Double, endian: Endianness, target: Bytes, offset: Int) -> Unit {
  int64_into_bytes(v.reinterpret_as_i64(), endian, target, offset)
}

/// Write bytes representation of an `Double` by little-endian into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn double_into_bytes_le(v: Double, target: Bytes, offset: Int) -> Unit {
  int64_into_bytes(v.reinterpret_as_i64(), Endianness::LittleEndian, target, offset)
}

/// Write bytes representation of an `Double` by big-endian into target `Bytes` at certain offset.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn double_into_bytes_be(v: Double, target: Bytes, offset: Int) -> Unit {
  int64_into_bytes(v.reinterpret_as_i64(), Endianness::BigEndian, target, offset)
}

test "double_into_bytes(series)" {
  let cases = [
    (
      -5.882781560676213e+94, // 0xd39c33c7f8175d9c (IEEE 754)
      0, 
      Bytes::[0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc], 
      Bytes::[0x9c, 0x5d, 0x17, 0xf8, 0xc7, 0x33, 0x9c, 0xd3, 0xcc, 0xcc], 
      Bytes::[0xd3, 0x9c, 0x33, 0xc7, 0xf8, 0x17, 0x5d, 0x9c, 0xcc, 0xcc],
    ),
    (
      5.2795633159472795e-219, // 0x129dd1b1e9f37d1a (IEEE 754)
      1, 
      Bytes::[0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa], 
      Bytes::[0xaa, 0x1a, 0x7d, 0xf3, 0xe9, 0xb1, 0xd1, 0x9d, 0x12, 0xaa], 
      Bytes::[0xaa, 0x12, 0x9d, 0xd1, 0xb1, 0xe9, 0xf3, 0x7d, 0x1a, 0xaa], 
    ),
    (
      -2.752623365577015e-164, // 0x9df95caf8b51fc5e (IEEE 754)
      2, 
      Bytes::[0xdf, 0xfd, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf], 
      Bytes::[0xdf, 0xfd, 0x5e, 0xfc, 0x51, 0x8b, 0xaf, 0x5c, 0xf9, 0x9d], 
      Bytes::[0xdf, 0xfd, 0x9d, 0xf9, 0x5c, 0xaf, 0x8b, 0x51, 0xfc, 0x5e],
    ),
  ]

  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (input, pos, original, le_expected, be_expected) = cases[icase];

    let buffer = original.copy()
    double_into_bytes(input, Endianness::LittleEndian, buffer, pos)
    test_bytes_eq(buffer, le_expected)?
    let buffer = original.copy()
    double_into_bytes(input, Endianness::BigEndian, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
    let buffer = original.copy()
    double_into_bytes(input, Endianness::NetworkEndian, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
    let buffer = original.copy()
    double_into_bytes_le(input, buffer, pos)
    test_bytes_eq(buffer, le_expected)?
    let buffer = original.copy()
    double_into_bytes_be(input, buffer, pos)
    test_bytes_eq(buffer, be_expected)?
  }
}

/// Get bytes representation of a `Double` by specified endianness.
pub fn double_to_bytes(v: Double, endian: Endianness) -> Bytes {
  let ret = Bytes::make(8)
  int64_into_bytes(v.reinterpret_as_i64(), endian, ret, 0)
  ret
}

/// Get bytes representation of a `Double` by little-endian.
pub fn double_to_bytes_le(v: Double) -> Bytes {
  let ret = Bytes::make(8)
  int64_into_bytes(v.reinterpret_as_i64(), Endianness::LittleEndian, ret, 0)
  ret
}

/// Get bytes representation of a `Double` by big-endian.
pub fn double_to_bytes_be(v: Double) -> Bytes {
  let ret = Bytes::make(8)
  int64_into_bytes(v.reinterpret_as_i64(), Endianness::BigEndian, ret, 0)
  ret
}

test "double_to_bytes(series)" {
  let input = 69664.25083987322; // 0x40f102040370abc0 (IEEE 754)
  let le_expected = Bytes::[0xc0, 0xab, 0x70, 0x03, 0x04, 0x02, 0xf1, 0x40]
  let be_expected = Bytes::[0x40, 0xf1, 0x02, 0x04, 0x03, 0x70, 0xab, 0xc0]
  test_bytes_eq(double_to_bytes(input, Endianness::LittleEndian), le_expected)?
  test_bytes_eq(double_to_bytes(input, Endianness::BigEndian), be_expected)?
  test_bytes_eq(double_to_bytes(input, Endianness::NetworkEndian), be_expected)?
  test_bytes_eq(double_to_bytes_le(input), le_expected)?
  test_bytes_eq(double_to_bytes_be(input), be_expected)?
}

/// Extract a `Double` from certain position of `Bytes` by specified endianness.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn double_from_bytes(bytes: Bytes, offset: Int, endian: Endianness) -> Double {
  @assertion.assert_true(offset + 8 <= bytes.length()).map_err(fn (msg) -> Unit { abort(msg) }).unwrap()
  let mut r = 0L
  for bd = 0; bd < 8; bd = bd + 1 {
    let bs = offset + endianness_index(bd, 8, endian)
    r = r.lor(bytes[bs].to_int().land(0xff).to_int64().lsl(8 * bd))
  }
  r.reinterpret_as_double()
}

/// Extract an `Double` from certain position of `Bytes` by little-endian.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn double_le_from_bytes(bytes: Bytes, offset: Int) -> Double {
  double_from_bytes(bytes, offset, Endianness::LittleEndian)
}

/// Extract an `Double` from certain position of `Bytes` by big-endian.
/// 
/// # Panics
/// 
/// 8 bytes of data are required from offset position. Panics when insufficient.
pub fn double_be_from_bytes(bytes: Bytes, offset: Int) -> Double {
  double_from_bytes(bytes, offset, Endianness::BigEndian)
}

test "double_from_bytes(series)" {
  let input = Bytes::[0x23, 0xb6, 0x1e, 0xc2, 0xa3, 0xbb, 0x19, 0x0f, 0x6d, 0x27]
  let cases = [
    (0, 6.322855833834645e-236, 1.1888038185948251e-136), 
    (1, 2.144245627950293e+217, -5.261764689278282e-48), 
    (2, 9.002687664123903e-119, 1.657251015555868e-160),
  ]
  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (pos, le_expected, be_expected) = cases[icase];
    @assertion.assert_eq(double_from_bytes(input, pos, Endianness::LittleEndian), le_expected)?
    @assertion.assert_eq(double_le_from_bytes(input, pos), le_expected)?
    @assertion.assert_eq(double_from_bytes(input, pos, Endianness::BigEndian), be_expected)?
    @assertion.assert_eq(double_from_bytes(input, pos, Endianness::NetworkEndian), be_expected)?
    @assertion.assert_eq(double_be_from_bytes(input, pos), be_expected)?
  }
}
