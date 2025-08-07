import 'package:intl/intl.dart';
import 'package:veseeta_scrapping/veseeta_scrapping.dart';

void main(List<String> arguments) async {
  DoctorsScrapping scrapping = DoctorsScrapping();
  await scrapping.start();
}

void timePrinter() {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(1754520765593);
  final formatted = DateFormat('yyyy/MM/dd hh:mm a').format(dateTime);
  print(formatted);
}
