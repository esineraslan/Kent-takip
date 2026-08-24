import 'dart:async';

import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/src/snapshot_codec.dart';

abstract interface class SnapshotStore {
  Future<AppSnapshotDto> read();

  Future<AppSnapshotDto> write(AppSnapshotDto snapshot);
}

final class SnapshotTransactionQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    final scheduled = _tail.then((_) => operation());
    unawaited(
      scheduled.then(completer.complete, onError: completer.completeError),
    );
    _tail = scheduled.then<void>((_) {}, onError: (_, _) {});
    return completer.future;
  }
}

final class InMemorySnapshotStore implements SnapshotStore {
  InMemorySnapshotStore({
    required AppSnapshotDto initial,
    required this.codec,
  }) : _current = initial {
    codec.validate(initial);
  }

  final SnapshotCodec codec;
  final SnapshotTransactionQueue _queue = SnapshotTransactionQueue();
  AppSnapshotDto _current;

  @override
  Future<AppSnapshotDto> read() async => _current;

  @override
  Future<AppSnapshotDto> write(AppSnapshotDto snapshot) {
    return _queue.run(() async {
      codec.validate(snapshot);
      if (snapshot.revision <= _current.revision) {
        fail(FailureCode.conflict, 'Revision ileri gitmelidir.');
      }
      _current = snapshot;
      return _current;
    });
  }
}

