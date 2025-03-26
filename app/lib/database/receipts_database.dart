import 'package:hive/hive.dart';

class ReceiptsDatabase {
  static final ReceiptsDatabase _instance = ReceiptsDatabase._internal();
  factory ReceiptsDatabase() => _instance;

  ReceiptsDatabase._internal();

  Future<void> insertReceipt(String url) async {
    final box = await Hive.openBox('receipts');
    await box.put(url, {'url': url});
  }

  Future<bool> hasReceipt(String url) async {
    final box = await Hive.openBox('receipts');
    return box.containsKey(url);
  }
}
