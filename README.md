# dispatcher ![pull-requests-badge](https://img.shields.io/badge/pull--requests-welcome-success.svg)

> Created by Alexandre Bolot on 19/03/2021

## Project objectives

The Dispatcher allows you to easily publish data and notify multiple listeners at once

The main idea is to behave like a light-weight Kafka producer/consumer API.
The content published on the Dispatcher feeds is dynamic,
which means you can publish basic values (`int`, `String`, etc.)
or decide to use it as an Event-driven publisher (if you use custom event objects)

You can create multiple feeds and multiple subscription for each feed.

## Example

```csharp
var dispatcher = Dispatcher(); // The Dispatcher is a singleton, calling the constructor always returns the same instance
var feedName = 'myIntegerFeed';
var subscriberName = 'mySubscriber';

dispatcher.createFeed(feedName);
  
dispatcher.subscribeTo(feedName, subscriberName, (feedItem) {
  print('value : ${feedItem.value}');
});

dispatcher.publish(feedName, 5);

// -> prints 'value : 5'

dispatcher.unsubscribeTo(feedName, subscriberName);

dispatcher.publish(feedName, 3);

// -> nothing happens, we 'testSubscriber' was unsubscribed
```