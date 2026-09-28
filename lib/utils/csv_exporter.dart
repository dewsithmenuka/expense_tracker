import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import '../models/wallet_card.dart';

class CsvExporter {
  /// Quotes cells that need it. Cells starting with = + - @ are prefixed
  /// with ' so Excel never runs them as a formula ("CSV injection").
  static String _cell(String value) {
    var v = value;
    if (v.isNotEmpty && '=+-@'.contains(v[0])) v = "'$v";
    final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
    v = v.replaceAll('"', '""');
    return needsQuotes ? '"$v"' : v;
  }

  static String build(
    List<Expense> expenses,
    WalletCard? Function(String?) cardOf,
  ) {
    final date = DateFormat('yyyy-MM-dd');
    final buf = StringBuffer('\uFEFF'); // BOM so Excel reads UTF-8 correctly
    buf.writeln('Date,Title,Category,Amount,Card,Note');
    for (final e in expenses) {
      buf.writeln([
        date.format(e.date),
        _cell(e.title),
        _cell(e.category.label),
        e.amount.toStringAsFixed(2),
        _cell(cardOf(e.cardId)?.displayName ?? ''),
        _cell(e.note ?? ''),
      ].join(','));
    }
    return buf.toString();
  }

  /// Writes the CSV to a temp file and opens the system share sheet.
  static Future<void> share({
    required List<Expense> expenses,
    required WalletCard? Function(String?) cardOf,
    required String fileLabel,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses_$fileLabel.csv');
    await file.writeAsString(build(expenses, cardOf));
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'My expenses',
    );
  }
}