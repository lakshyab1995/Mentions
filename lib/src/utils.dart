bool isDigit(int c) {
  return c >= 0x30 && c <= 0x39;
}

bool isEmpty(String str) => str == null || str.isEmpty;

bool isLetter(int c) {
  return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
}

bool isLetterOrDigit(int c) {
  return isLetter(c) || isDigit(c);
}
