import 'package:audiokiddo/features/insights/events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('share targets become referral channels', () {
    expect(shareChannel('net.whatsapp.WhatsApp.ShareExtension'), 'whatsapp');
    expect(shareChannel('com.facebook.Messenger.ShareExtension'), 'messenger');
    expect(shareChannel('com.apple.UIKit.activity.CopyToPasteboard'), 'link_copy');
    expect(shareChannel('com.apple.UIKit.activity.Message'), 'sms');
    expect(shareChannel('com.example.notes'), 'other');
    expect(shareChannel(''), 'unknown');
  });
}
