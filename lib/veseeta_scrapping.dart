import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:veseeta_scrapping/progress_checker.dart';

class DoctorsScrapping {
  String endPoint =
      'https://vezeeta-mobile-gateway.vezeetaservices.com/api/Search';
  String filePath = 'output/doctors/data.json';

  IOSink? _sink;

  final ProgressChecker _progressChecker = ProgressChecker();

  Future<void> start() async {
    int page = _progressChecker.checkProgress(ProgressKeys.doctorsSearch);
    if (page == -1) {
      page = 1;
    } else {
      // this is for getting the next page
      // as if the page is not -1 this means that we have already fetched it's data so let's start from the next page
      page++;
    }
    while (true) {
      var data = await _getPage(page);
      int doctorNum = (data['Result'] as List).length;
      if (doctorNum == 0) {
        print('No more data to fetch.');
        _closeFile();

        break;
      }
      print('Fetched page $page: $doctorNum items');
      _writeToFile(data);
      _progressChecker.updateProgress(ProgressKeys.doctorsSearch, page);
      page++;

      // You can add a delay here if needed to avoid hitting the server too fast
      // await Future.delayed(Duration(seconds: 2));
    }
  }

  Future<Map> _getPage(int pageNumber) async {
    final dio = Dio();

    final headers = {
      'User-Agent': 'okhttp/4.11.0',
      'Accept-Encoding': 'gzip',
      'authorization': '99999999-9999-9999-9999-000000000000',
      'countryid': '1',
      'language_cache': '2',
      'language': 'ar-EG',
      'cache-control': 'max-age=7200',
      'country_cache': '1',
      'languageid': '2',
      'accept-language': 'ar-EG',
      'regionid': 'Africa/Cairo',
      'brandkey': '7B2BAB71-008D-4469-A966-579503B3C719',
      'content-type': 'application/json',
      'x-vzt-time': '1754529550537',
      'x-vzt-token': '',
      'x-vzt-authorization':
          'd3a6ccb60c656bb7a6b07899def51de430d17ca0fb7d33b91f912c2c0ea5cfb2',
    };

    final queryParams = {
      // 'Speciality': 'spec00000005EG',
      'Page': pageNumber,
      'BookingTypes': 'physical',
    };
    try {
      final response = await dio.get(
        endPoint,
        queryParameters: queryParams,
        options: Options(headers: headers, responseType: ResponseType.json),
      );
      var data = response.data as Map<String, dynamic>;
      return data;
    } on DioException catch (e) {
      print('Request failed: ${e.response?.data}');
      rethrow;
    }
  }

  void _openFile() {
    File file = File(filePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    _sink = file.openWrite(mode: FileMode.writeOnlyAppend);
  }

  void _writeToFile(Map data) {
    if (_sink == null) {
      _openFile();
    }
    _sink!.write(json.encode(data));
  }

  void _closeFile() {
    _sink?.close();
  }
}

String dioRequestToCurl(RequestOptions options) {
  final buffer = StringBuffer();

  buffer.write('curl -X ${options.method}');

  // Headers
  options.headers.forEach((key, value) {
    buffer.write(' -H "$key: $value"');
  });

  // Data (Body)
  if (options.data != null) {
    var data = options.data;

    // Convert Map or FormData to JSON
    if (data is Map) {
      data = jsonEncode(data);
    } else if (data is FormData) {
      final fields = data.fields.map((e) => '"${e.key}=${e.value}"').join('&');
      data = fields;
    }

    buffer.write(" --data '$data'");
  }

  // URL
  buffer.write(' "${options.uri.toString()}"');

  return buffer.toString();
}
