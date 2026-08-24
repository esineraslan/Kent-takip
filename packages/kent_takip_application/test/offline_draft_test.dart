import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:test/test.dart';

void main() {
  test('citizen draft bağlantı kesintisinde serileştirilip geri yüklenir', () async {
    final queue = OfflineDraftQueue(store: InMemoryDraftStore());
    final command = CreateReportCommand(
      actorId: 'usr_citizen_demo_001',
      clientMutationId: 'draft_mutation_001',
      expectedRevision: 4,
      category: 'lighting',
      description: 'Sokak lambası çalışmıyor.',
      latitude: 41.0,
      longitude: 29.0,
    );

    await queue.save(command);
    final restored = await queue.load(command.actorId);
    expect(restored?.clientMutationId, command.clientMutationId);
    expect(restored?.description, command.description);
    await queue.clear(command.actorId);
    expect(await queue.load(command.actorId), isNull);
  });
}
