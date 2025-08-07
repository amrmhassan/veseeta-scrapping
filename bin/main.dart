import 'package:intl/intl.dart';
import 'package:veseeta_scrapping/constants/endpoints.dart';
import 'package:veseeta_scrapping/constants/links.dart';
import 'package:veseeta_scrapping/org_request.dart';
import 'package:veseeta_scrapping/veseeta_scrapping.dart';
import 'package:veseeta_scrapping/vezeeta_auth.dart';

void main(List<String> arguments) async {
  DoctorsScrapping scrapping = DoctorsScrapping();
  await scrapping.start();
  var output = await VezeetaApiClient().searchDoctors();
}

void timePrinter() {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(1754520765593);
  final formatted = DateFormat('yyyy/MM/dd hh:mm a').format(dateTime);
  print(formatted);
}
