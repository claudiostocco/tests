void main(List<String> args) {
  final a = true;
  final b = true;
  final c = true;

  if (a && b && c)
    print('true');
  else
    print('false');

  if (a || b || c)
    print('true');
  else
    print('false');

  if (b || c)
    print('true');
  else
    print('false');

  if (b ^ c)
    print('true');
  else
    print('false');

  if (!a)
    print('true');
  else
    print('false');
}
