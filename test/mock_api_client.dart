import 'package:mockito/mockito.dart';
import 'package:vitalsense/services/api_client.dart';
import 'package:mockito/annotations.dart';

class MockApiClient extends Mock implements ApiClient {}


@GenerateMocks([ApiClient])
void main() {}
