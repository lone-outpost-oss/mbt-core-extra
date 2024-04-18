fn test_bytes_eq(l: Bytes, r: Bytes) -> Result[Unit, String] {
  if l.length() == r.length() {
    for i = 0; i < l.length(); i = i + 1 {
      if l[i] != r[i] {
        let msg = Buffer::make(16)
        msg.write_string("byte mismatch at \(i): ")
        msg.write_string(l[i].to_string())
        msg.write_string(" != ")
        msg.write_string(r[i].to_string())
        return Err(msg.to_string())
      }
    }
    Ok(())
  } else {
    let msg = Buffer::make(16)
    msg.write_string("length mismatch: ")
    msg.write_string(l.length().to_string())
    msg.write_string(" != ")
    msg.write_string(r.length().to_string())
    Err(msg.to_string())
  }
}
