// ignore_for_file: avoid_print
import 'package:dio/dio.dart';

const _clientVersion = '20.11.39';
const _ua =
    'com.google.android.youtube/$_clientVersion (Linux; U; Android 13) gzip';

final _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 12),
  receiveTimeout: const Duration(seconds: 15),
));

Future<Map<String, dynamic>> _innerTube(String endpoint,
    {String? videoId, String? query}) async {
  final resp = await _dio.post<Map<String, dynamic>>(
    'https://www.youtube.com/youtubei/v1/$endpoint?prettyPrint=false',
    data: {
      'context': {
        'client': {
          'clientName': 'ANDROID',
          'clientVersion': _clientVersion,
          'hl': 'en',
          'gl': 'US',
        },
      },
      if (videoId != null) 'videoId': videoId,
      if (query != null) 'query': query,
      if (query != null) 'params': 'EgIQAQ%3D%3D',
      if (videoId != null) 'contentCheckOk': true,
      if (videoId != null) 'racyCheckOk': true,
    },
    options: Options(
      responseType: ResponseType.json,
      headers: {
        'User-Agent': _ua,
        'X-Youtube-Client-Name': '3',
        'X-Youtube-Client-Version': _clientVersion,
        'Origin': 'https://www.youtube.com',
      },
    ),
  );
  return resp.data ?? {};
}

Map? _firstVideo(dynamic node) {
  if (node is Map) {
    for (final key in ['videoRenderer', 'compactVideoRenderer']) {
      final v = node[key];
      if (v is Map && v['videoId'] is String) return v;
    }
    for (final value in node.values) {
      final f = _firstVideo(value);
      if (f != null) return f;
    }
  } else if (node is List) {
    for (final value in node) {
      final f = _firstVideo(value);
      if (f != null) return f;
    }
  }
  return null;
}

Future<String> gateStatus(String url) async {
  if (url.isEmpty) return 'no-url';
  try {
    final r = await _dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        validateStatus: (_) => true,
        headers: {'User-Agent': _ua},
      ),
    );
    final code = r.statusCode;
    if (code == 200 || code == 206) return 'OK';
    if (code == 403) return '403';
    return 'HTTP$code';
  } catch (e) {
    return 'ERR';
  }
}

Future<void> main(List<String> args) async {
  final queries = args.isEmpty
      ? ['Islandia', 'عمرو دياب اغنية', 'Quran recitation', 'Mashrou leila', 'Amr Diab']
      : args;
  for (final q in queries) {
    final search = await _innerTube('search', query: q);
    final video = _firstVideo(search);
    if (video == null) {
      print('[$q] no video found');
      continue;
    }
    final id = video['videoId'];
    final data = await _innerTube('player', videoId: id);
    final details = data['videoDetails'] as Map?;
    final secs = int.tryParse('${details?['lengthSeconds']}') ?? 0;
    final streaming = data['streamingData'] as Map?;
    final byItag = <int, Map<String, dynamic>>{};
    if (streaming != null) {
      for (final key in ['formats', 'adaptiveFormats']) {
        final list = streaming[key];
        if (list is List) {
          for (final f in list) {
            if (f is Map && f['itag'] != null) {
              byItag[int.parse('${f['itag']}')] = Map<String, dynamic>.from(f);
            }
          }
        }
      }
    }
    final it18 = byItag[18];
    final r18 = it18 == null
        ? 'n/a'
        : '${int.parse('${it18['contentLength'] ?? 0}') * 8 ~/ (secs > 0 ? secs : 1) ~/ 1000}kbps';
    print('[$q] id=$id dur=${secs}s itag18=$r18');
    for (final it in [140, 251]) {
      final f = byItag[it];
      if (f == null) {
        print('  itag$it: not present');
        continue;
      }
      final url = f['url']?.toString();
      final abr = int.tryParse('${f['bitrate'] ?? ''}') ?? 0;
      final g = await gateStatus(url ?? '');
      print('  itag$it: ${(abr / 1000).round()}kbps direct=${url?.isNotEmpty} gate=$g');
    }
  }
}
