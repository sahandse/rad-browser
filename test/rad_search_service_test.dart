import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rad_browser/features/search/data/rad_search_service.dart';
import 'package:rad_browser/features/settings/domain/app_settings.dart';

void main() {
  test('parses Google-style results', () async {
    final client = MockClient((request) async {
      return http.Response('''
        <html><body>
          <div class="g">
            <a href="https://example.com/page"><h3>نمونه نتیجه</h3></a>
            <div class="VwiC3b">توضیح کوتاه نتیجه نمونه</div>
          </div>
        </body></html>
      ''', 200, headers: {'content-type': 'text/html; charset=utf-8'});
    });

    final service = RadSearchService(client: client);
    final response = await service.search(
      query: 'نمونه',
      engine: RadSearchEngine.google,
    );

    expect(response.results, isNotEmpty);
    expect(response.results.first.title, 'نمونه نتیجه');
    expect(response.results.first.url, 'https://example.com/page');
  });

  test('discovers and submits an internal provider form', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'zarebin.ir' && request.url.path == '/') {
        return http.Response('''
          <html><body>
            <form action="/search" method="get">
              <input type="search" name="q" />
            </form>
          </body></html>
        ''', 200, headers: {'content-type': 'text/html; charset=utf-8'});
      }
      if (request.url.host == 'zarebin.ir' && request.url.path == '/search') {
        return http.Response('''
          <html><body>
            <div class="result">
              <a href="https://example.ir/article"><h3>نتیجه داخلی</h3></a>
              <p>توضیح نتیجه داخلی</p>
            </div>
          </body></html>
        ''', 200, headers: {'content-type': 'text/html; charset=utf-8'});
      }
      return http.Response('', 404);
    });

    final service = RadSearchService(client: client);
    final response = await service.search(
      query: 'آزمایش',
      engine: RadSearchEngine.zarebin,
    );

    expect(response.results, isNotEmpty);
    expect(response.results.first.title, contains('نتیجه داخلی'));
    expect(response.results.first.url, 'https://example.ir/article');
  });
}
