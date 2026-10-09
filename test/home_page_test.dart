import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:web_scanner_pro/features/home/home_page.dart';

void main() {
  testWidgets('trang chủ hiển thị các chức năng chính trên màn hình hẹp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
    expect(find.text('Kết nối WhatsApp Web'), findsOneWidget);
    expect(find.text('Lưu trạng thái'), findsOneWidget);
    expect(find.text('Lịch sử thông báo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
