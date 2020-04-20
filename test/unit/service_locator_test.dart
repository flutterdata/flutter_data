import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

void main() async {
  test('#all', () {
    final injection = DataServiceLocator<String>();
    injection.register('hello');
    expect(injection.locator<String>(), 'hello');
  });
}
