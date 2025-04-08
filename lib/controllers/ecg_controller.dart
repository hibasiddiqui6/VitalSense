import 'dart:collection';

class ECGController {
  static final ECGController _instance = ECGController._internal();
  factory ECGController() => _instance;
  ECGController._internal();

  static ECGController? get instance => _instance;

  final List<double> _buffer = [];

  void addPoint(double value) {
    _buffer.add(value);
    if (_buffer.length > 500) _buffer.removeAt(0); // Optional cap
  }

  UnmodifiableListView<double> get buffer => UnmodifiableListView(_buffer);

  double? popNextPoint() {
    if (_buffer.isEmpty) return null;
    return _buffer.removeAt(0);
  }

  void clear() => _buffer.clear();
}
