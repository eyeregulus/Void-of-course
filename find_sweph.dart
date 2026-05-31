import 'dart:isolate';
void main() async {
  print(await Isolate.resolvePackageUri(Uri.parse('package:sweph/sweph.dart')));
}
