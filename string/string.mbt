/// The type of a word (16-bit) appears in a UTF-16 sequence:  
/// 
///  - `BMP`: Basic Multilingual Plane. (including `0x0000–0xD7FF` and `0xE000–0xFFFF`)  
///  - `HighSurrogate`: The first word of a surrogate pair. (including `0xD800–0xDBFF`)  
///  - `LowSurrogate`: The second word of a surrogate pair. (including `0xDC00–0xDFFF`)  
pub enum Utf16WordType {
  BMP
  HighSurrogate
  LowSurrogate
} derive(Eq, Debug, Show)

/// Get the char appeared at n-th word (16-bit) of input string.
/// 
/// # Examples
/// 
/// Iterate a string including `U+10000` by valid chars (unicode code point) using a `while` loop:
/// 
/// ```moonbit
/// let str = "\u{6708}\u{1f430}\u{5154}" // 月🐰兔
/// let mut i = 0
/// while i < str.length() {
///   let (ch, ty) = get_valid_char_at(str, i)
///   println(ch)
/// 
///   // advance by 2 words on a surrogate pair
///   i += if ty != Utf16WordType::BMP { 1 } else { 2 } 
/// }
/// ```
/// 
/// # Panics
/// 
/// Panics if index out of range, or any invalid value (code point or surrogate pair) appears at specified position.
pub fn get_valid_char_at(str: String, idx_word: Int) -> (Char, Utf16WordType) {
  if 0 <= idx_word && idx_word < str.length() {
    let c = str.get(idx_word)
    let w = c.to_int()
    if (0x0000 <= w && w <= 0xD7FF) || (0xE000 <= w && w <= 0xFFFF) {
      (c, BMP)
    } else if 0xD800 <= w && w <= 0xDBFF {
      if idx_word + 1 < str.length() {
        let wl = str.get(idx_word + 1).to_int()
        (combine_surrogate_pair_int(w, wl), HighSurrogate)
      } else {
        abort("invalid string: high surrogate appeared at the ending")
      }
    } else if 0xDC00 <= w && w <= 0xDFFF {
      if idx_word - 1 >= 0 {
        let wh = str.get(idx_word - 1).to_int()
        (combine_surrogate_pair_int(wh, w), LowSurrogate)
      } else {
        abort("invalid string: low surrogate appeared at the beginning")
      }
    } else {
      abort("unreachable code reached")
    }
  } else {
    let length = str.length()
    abort("`idx_word` out of range (length of string = \(length))")
  }
}

test "get_valid_char_at" {
  // standard test
  let str = "a\u{6587}\u{10000}\u{1F408}"
  let expected = [
    ('a', Utf16WordType::BMP), 
    ('\u{6587}', BMP), 
    ('\u{10000}', HighSurrogate),
    ('\u{10000}', LowSurrogate),
    ('\u{1F408}', HighSurrogate),
    ('\u{1F408}', LowSurrogate),
  ]
  for i = 0; i < str.length(); i = i + 1 {
    let (ch, ty) = get_valid_char_at(str, i)
    @assertion.assert_eq(ch, expected[i].0)?
    @assertion.assert_eq(ty, expected[i].1)?
  }
  
  // doctest (keep this part same to the doc comments)
  let str = "\u{6708}\u{1f430}\u{5154}" // 月🐰兔
  let mut i = 0
  while i < str.length() {
    let (_ch, ty) = get_valid_char_at(str, i)
    // println(ch) // comment out to omit display

    // advance by 2 words on a surrogate pair
    i += if ty != Utf16WordType::BMP { 1 } else { 2 } 
  }
}

fn combine_surrogate_pair_int(high: Int, low: Int) -> Char {
  if high.land(0xFFFFFC00) != 0x0000D800 {
    abort("invalid high surrogate \(high)")
  } else if low.land(0xFFFFFC00) != 0x0000DC00 {
    abort("invalid low surrogate \(low)")
  }
  
  let codepoint = (high.land(0x000003FF).lsl(10) + low.land(0x000003FF)) + 0x00010000
  Char::from_int(codepoint)
}
