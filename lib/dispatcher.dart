/*..............................................................................
 . Copyright (c)
 .
 . The dispatcher.dart class was created by : Alexandre Bolot
 .
 . As part of the Dispatcher project
 .
 . Last modified : 19/03/2021
 .
 . Contact : contact.alexandre.bolot@gmail.com
 .............................................................................*/

library dispatcher;

/// Defines a callback used to notify a subscriber when a new [feedItem] is published
typedef OnNewItem = void Function(FeedItem feedItem);

/// The [Dispatcher] allows you to easily publish data and notify multiple listeners at once
///
/// The main idea is to behave like a light-weight Kafka producer/consumer API
/// The content published on the [Dispatcher] feeds is dynamic,
/// which means you can publish basic values (integers, strings, etc.)
/// or decide to use it as an Event-driven publisher (if you use custom event objects)
///
/// You can create multiple feeds and multiple subscription for each feed.
class Dispatcher {
  // ----- Singleton Section ----- //

  static final Dispatcher _instance = Dispatcher._internal();

  /// Returns the singleton instance
  factory Dispatcher() => _instance;

  Dispatcher._internal();

  // ----------------------------- //

  final Map<String, Feed> _feeds = {};
  bool _silent = false;

  /// Changes the [silent] attribute of the [Dispatcher] (if null, defaults to false)
  ///
  /// The [silent] attribute is used to suppress throwing exceptions.
  /// For example when publishing on a feed that does not exist, if the [Dispatcher] is silent,
  /// nothing happens and no exception is thrown.
  Dispatcher setSilent(bool shouldBeSilent) => this.._silent = shouldBeSilent ?? false;

  /// Creates and adds a new [Feed] to the [Dispatcher] and associates it with a [feedName]
  ///
  /// If [override] is true, it will replace the feed previously associated with [feedName]. <br>
  /// Else throws an exception if [feedName] is already used.
  ///
  /// Returns the Dispatcher instance to allow chained method calls.
  Dispatcher createFeed(String feedName, {bool override = false}) {
    if (override) {
      _feeds.addOrReplace(feedName, Feed());
      return this;
    }

    if (_checkNotContains(feedName)) {
      _feeds.putIfAbsent(feedName, () => Feed());
    }
    return this;
  }

  /// Creates a new subscription to a feed
  ///
  /// The [callback] will be called whenever a new [FeedItem] is added to the feed.
  /// The [subscriberName] is used to allow unsubscribing from the feed later -> to stop receiving updates
  ///
  /// Returns the Dispatcher instance to allow chained method calls.
  /// ---
  /// ```
  /// Dispatcher().subscribeTo('myIntegerFeed', 'testSubscriber', (feedItem) {
  ///   print('published at : ${feedItem.publishedAt}');
  ///   print('value : ${feedItem.value}');
  /// });
  /// ```
  Dispatcher subscribeTo(String feedName, String subscriberName, OnNewItem callback) {
    if (_checkContains(feedName)) {
      _feeds[feedName].subscribe(subscriberName, callback);
    }
    return this;
  }

  /// Allows you to stop receiving updates when new [FeedItem]s are added to the feed.
  ///
  /// Returns the Dispatcher instance to allow chained method calls.
  Dispatcher unsubscribeTo(String feedName, String subscriber) {
    if (_checkContains(feedName)) {
      _feeds[feedName].unsubscribe(subscriber);
    }
    return this;
  }

  /// Publishes a new [FeedItem] on the given feed
  ///
  /// The [FeedItem] will be created the given [value]
  /// and a [publishedAt] attribute set to [DateTime.now()]
  ///
  /// Returns the Dispatcher instance to allow chained method calls.
  /// ---
  /// ```
  /// Dispatcher().publish('myIntegerFeed', 5);
  /// Dispatcher().publish('myJsonFeed', { name: 'John Smith', age: 32 });
  /// Dispatcher().publish('myUserFeed', User('JohnSmith', 32));
  /// ```
  Dispatcher publish(String feedName, dynamic value) {
    if (_checkContains(feedName)) {
      _feeds[feedName].publish(value);
    }
    return this;
  }

  bool _checkContains(String feedName) {
    if (_feeds.notContains(feedName)) {
      if (_silent) {
        return false;
      } else {
        throw 'Dispatcher : Trying to access "$feedName" which could not be found';
      }
    }

    return true;
  }

  bool _checkNotContains(String feedName) {
    if (_feeds.containsKey(feedName)) {
      if (_silent) {
        return false;
      } else {
        throw 'Dispatcher : Trying to create a feed that already exists : "$feedName"';
      }
    }

    return true;
  }
}

/// A [Feed] containing a list of [FeedItem]s and notifying subscribers whenever a new [FeedItem] is added
class Feed {
  final List<FeedItem> _items = [];
  final Map<String, OnNewItem> _listeners = {};

  /// Creates and adds a new [FeedItem] to this feed,
  /// containing the given [value] and notifies every subscriber
  ///
  /// Returns the newly created [FeedItem]
  FeedItem publish(value) {
    var newItem = FeedItem(value);
    _items.add(newItem);
    _listeners.values.forEach((callback) => callback(newItem));
    return newItem;
  }

  /// Creates a new subscription to this feed
  ///
  /// The [callback] will be called whenever a new [FeedItem] is added to this feed.
  /// The [subscriberName] is used to allow unsubscribing from the feed later -> to stop receiving updates
  ///
  /// Returns this [Feed] instance allow chained method calls.
  /// ---
  /// ```
  /// Dispatcher().subscribeTo('myIntegerFeed', 'testSubscriber', (feedItem) {
  ///   print('published at : ${feedItem.publishedAt}');
  ///   print('value : ${feedItem.value}');
  /// });
  /// ```
  Feed subscribe(String subscriber, OnNewItem callback) {
    _listeners.putIfAbsent(subscriber, () => callback);
    return this;
  }

  /// Allows you to stop receiving updates when new [FeedItem]s are added to this feed.
  ///
  /// Returns this [Feed] instance allow chained method calls.
  Feed unsubscribe(String subscriber) {
    _listeners.remove(subscriber);
    return this;
  }
}

/// An item of a [Dispatcher]'s [Feed]
class FeedItem {
  /// Value published on the feed
  dynamic value;

  /// Date and time when the item was published on the feed
  final DateTime publishedAt = DateTime.now();

  /// Basic constructor
  FeedItem(this.value);
}

extension _MapExtension on Map<String, Feed> {
  bool notContains(String key) => !this.containsKey(key);

  void addOrReplace(String key, Feed value) {
    if (this.containsKey(key)) {
      this[key] = value;
    } else {
      this.putIfAbsent(key, () => value);
    }
  }
}
