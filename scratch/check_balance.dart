import 'dart:io';

void main() {
  final content = File('lib/features/sales/ui/pos_screen.dart').readAsStringSync();
  int parens = 0;
  int braces = 0;
  int brackets = 0;
  for (int i = 0; i < content.length; i++) {
    if (content[i] == '(') parens++;
    if (content[i] == ')') parens--;
    if (content[i] == '{') braces++;
    if (content[i] == '}') braces--;
    if (content[i] == '[') brackets++;
    if (content[i] == ']') brackets--;
  }
  print('Parens: $parens');
  print('Braces: $braces');
  print('Brackets: $brackets');
}
