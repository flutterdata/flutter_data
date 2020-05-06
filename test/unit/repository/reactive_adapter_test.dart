import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';
import 'package:async/async.dart';

import '../../models/person.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  // test('watchAll', () async {
  //   var repo = injection.locator<Repository<Person>>();
  //   // make sure there are no items in local storage from previous tests
  //   await repo.box.clear();
  //   expect(repo.box.keys, isEmpty);

  //   var stream = StreamQueue(repo.watchAll().stream);
  //   (repo as PersonPollAdapter).generatePeople();

  //   final matcher = predicate((p) {
  //     return p is Person && p.name.startsWith('zzz-') && p.age < 89;
  //   });

  //   expect(stream, mayEmitMultiple(isEmpty));

  //   await expectLater(
  //     stream,
  //     emitsInOrder([
  //       [matcher],
  //       [matcher, matcher],
  //       [matcher, matcher, matcher]
  //     ]),
  //   );

  //   expect(repo.box.keys.length, 3);
  // });

  // test('ensure there is never more than the amount of real IDs', () async {
  //   var repo = injection.locator<Repository<Person>>();
  //   // make sure there are no items in local storage from previous tests
  //   await repo.localAdapter.clear();

  //   expect(repo.localAdapter.keys.length, 0);

  //   var stream = StreamQueue(repo.watchAll().stream);

  //   var matcherMaxLength =
  //       (int length) => predicate((List<Person> s) => s.length <= length);

  //   // ignore: unawaited_futures
  //   (() async {
  //     for (int i = 0; i < 15; i++) {
  //       // wait for debounce with some margin
  //       await Future.delayed(Duration(milliseconds: 50));
  //       List.generate(28, (_) => Person.generateRandom(repo, withId: true));
  //     }
  //   })();

  //   // ignore empty
  //   expect(stream, mayEmitMultiple(isEmpty));

  //   await expectLater(
  //     stream,
  //     emitsInOrder([
  //       matcherMaxLength(28),
  //       matcherMaxLength(56),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //     ]),
  //   );
  // });
}
