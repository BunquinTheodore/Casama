import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_repository.dart';

final repositoryProvider = ChangeNotifierProvider<MockRepository>((ref) {
  return MockRepository();
});
