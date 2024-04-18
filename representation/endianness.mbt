/// Byte order, aka "endianness".
/// 
///  - `LittleEndian`: Little-endian.
///  - `BigEndian`: Big-endian.
///  - `NetworkEndian`: Network byte order defined by [IETF RFC 1700](https://datatracker.ietf.org/doc/html/rfc1700).
/// 
/// note: 
///  - Little-endian is the de-facto standard practice for current computer architectures, and the standardized byte order of WASM. 
///  - `NativeEndian` (system native-endian) may be introduced in the future.
pub enum Endianness {
  LittleEndian
  BigEndian
  NetworkEndian
} derive(Debug, Show, Eq)

/// Get destination byte index of specified endiness, assuming source is little-endianness.
fn endianness_index(le_index: Int, bytes_count: Int, endian: Endianness) -> Int {
  if endian == Endianness::LittleEndian {
    le_index
  } else if endian == Endianness::BigEndian || endian == Endianness::NetworkEndian {
    bytes_count - 1 - le_index
  } else {
    abort("invalid endianness")
  }
}