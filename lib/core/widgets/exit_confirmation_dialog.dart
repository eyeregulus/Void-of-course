import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:void_of_course/features/ads/widgets/reusable_native_ad_widget.dart';

class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({super.key});

  void _requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    // The `openStoreListing` method requires the app's identifier. For Android, this is the applicationId.
    await inAppReview.openStoreListing(appStoreId: 'dev.lioluna.voidofcourse');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('정말 앱을 나가시겠습니까?'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [ReusableNativeAdWidget()],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('종료'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            _requestReview();
            Navigator.of(context).pop(false);
          },
          child: const Text('리뷰하기'),
        ),
      ],
    );
  }
}
