import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tkp_collector_app/main.dart';

void main() {
  testWidgets('Form utama tampil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TkpApp());
    expect(find.text('Ambil Foto'), findsOneWidget);
    expect(find.text('Ambil GPS'), findsOneWidget);
    expect(find.text('Kirim ke Server'), findsOneWidget);

    await tester.tap(find.text('Kirim ke Server'));
    await tester.pump();
    expect(find.text('Isi nomor perkara dulu.'), findsOneWidget);
  });
}
