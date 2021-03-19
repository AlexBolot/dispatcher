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
typedef OnNewItem<T> = void Function(FeedItem<T> feedItem);

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
  /// - If [override] is true, it will replace the feed previously associated with [feedName]. <br>
  /// Else throws an exception if [feedName] is already used.
  ///
  /// - Returns the Dispatcher instance to allow chained method calls.
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
  Dispatcher subscribeTo(String feedName, String subscriberName, OnNewItem callback) {
    if (_checkContains(feedName)) {
      _feeds[feedName].subscribe(subscriberName, callback);
    }
    return this;
  }

  /// Allows you to stop receiving updates when new [FeedItem]s are added to the feed.
  Dispatcher unsubscribeTo(String feedName, String subscriber) {
    if (_checkContains(feedName)) {
      _feeds[feedName].unsubscribe(subscriber);
    }
    return this;
  }

  /// Publishes a new [FeedItem] on the given feed
  ///
  ///
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

class Feed<T> {
  final List<FeedItem> _items = [];
  final Map<String, OnNewItem<T>> _listeners = {};

  publish(value) {
    var newItem = FeedItem(value);
    _items.add(newItem);
    _listeners.values.forEach((callback) => callback(newItem));
  }

  subscribe(String subscriber, OnNewItem callback) {
    _listeners.putIfAbsent(subscriber, () => callback);
  }

  unsubscribe(String subscriber) {
    _listeners.remove(subscriber);
  }
}

class FeedItem<T> {
  T value;
  final DateTime publishedAt = DateTime.now();

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
