String capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  final firstChar = text[0];
  if (!RegExp(r'[a-zA-Z]').hasMatch(firstChar)) return text;
  if (firstChar == firstChar.toUpperCase()) return text;
  return text[0].toUpperCase() + text.substring(1);
}
