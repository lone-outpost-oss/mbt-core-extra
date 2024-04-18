/// Get bytes representation of a `Double` by specified endianness.
pub fn double_to_bytes(v: Double, endian: Endianness) -> Bytes {
  int64_to_bytes(v.reinterpret_as_i64(), endian)
}

/// Get bytes representation of a `Double` by little-endian.
pub fn double_to_bytes_le(v: Double) -> Bytes {
  double_to_bytes(v, Endianness::LittleEndian)
}

/// Get bytes representation of a `Double` by big-endian.
pub fn double_to_bytes_be(v: Double) -> Bytes {
  double_to_bytes(v, Endianness::BigEndian)
}

test "double_to_bytes(series)" {
  let input = 69664.25083987322; // == 0x40f102040370abc0 (IEEE 754)
  let le_expected = Bytes::make(8, 0)
  le_expected[0] = b'\xc0'.to_int()
  le_expected[1] = b'\xab'.to_int()
  le_expected[2] = b'\x70'.to_int()
  le_expected[3] = b'\x03'.to_int()
  le_expected[4] = b'\x04'.to_int()
  le_expected[5] = b'\x02'.to_int()
  le_expected[6] = b'\xf1'.to_int()
  le_expected[7] = b'\x40'.to_int()
  let be_expected = Bytes::make(8, 0)
  be_expected[0] = le_expected[7]
  be_expected[1] = le_expected[6]
  be_expected[2] = le_expected[5]
  be_expected[3] = le_expected[4]
  be_expected[4] = le_expected[3]
  be_expected[5] = le_expected[2]
  be_expected[6] = le_expected[1]
  be_expected[7] = le_expected[0]
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
    r = r.lor(bytes[bs].land(0xff).to_int64().lsl(8 * bd))
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
  let input = Bytes::make(10, 0)
  input[0] = b'\x23'.to_int()
  input[1] = b'\xb6'.to_int()
  input[2] = b'\x1e'.to_int()
  input[3] = b'\xc2'.to_int()
  input[4] = b'\xa3'.to_int()
  input[5] = b'\xbb'.to_int()
  input[6] = b'\x19'.to_int()
  input[7] = b'\x0f'.to_int()
  input[8] = b'\x6d'.to_int()
  input[9] = b'\x27'.to_int()
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
