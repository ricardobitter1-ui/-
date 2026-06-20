import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/utils/firestore_timestamp_parse.dart';

void main() {
  test('aceita Timestamp', () {
    final at = DateTime(2026, 6, 12, 10);
    expect(
      parseFirestoreDateTime(Timestamp.fromDate(at)),
      at,
    );
  });

  test('aceita String ISO', () {
    expect(
      parseFirestoreDateTime('2026-06-12T10:30:00.000Z'),
      isNotNull,
    );
  });

  test('null para valor desconhecido', () {
    expect(parseFirestoreDateTime({'bad': true}), isNull);
  });
}
