import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/domain_check_viewmodel.dart';

void main() {
  test('domain check succeeds after initializing the panel HTTP provider', () async {
    var initializeCount = 0;
    var successCount = 0;

    final viewModel = DomainCheckViewModel(
      initializeHttpService: () async {
        initializeCount++;
      },
      onCheckSucceeded: () {
        successCount++;
      },
    );
    addTearDown(viewModel.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(initializeCount, 1);
    expect(successCount, 1);
    expect(viewModel.isChecking, isFalse);
    expect(viewModel.isSuccess, isTrue);
  });
}
