import 'package:dispatcher/dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('testing create, subscribeTo, publish and unsubscribeTo', () {
    var dispatcher = Dispatcher();
    var feedName = 'myFeed';
    var subscriberName = 'mySubscriber';
    var result;

    dispatcher.createFeed(feedName);

    dispatcher.subscribeTo(feedName, subscriberName, (feedItem) {
      result = feedItem.value;
    });

    dispatcher.publish(feedName, 5);

    expect(result, 5);

    dispatcher.unsubscribeTo(feedName, subscriberName);

    dispatcher.publish(feedName, 3);

    expect(result, 5);
  });
}
