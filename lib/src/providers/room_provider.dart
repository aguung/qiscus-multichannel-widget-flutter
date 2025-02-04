import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

import 'messages_provider.dart';
import 'qiscus_sdk_provider.dart';
import 'room_id_provider.dart';

var _roomDataProvider =
    FutureProvider.family.autoDispose((ref, int roomId) async {
  var qiscus = await ref.watch(qiscusProvider.future);

  return qiscus
      .getChatRoomWithMessages(roomId: roomId)
      .timeout(const Duration(seconds: 1))
      .catchError(
    // ignore: body_might_complete_normally_catch_error
    (_) {
      ref.invalidateSelf();
    },
    test: (err) => err is TimeoutException,
  );
});

final roomProvider = FutureProvider.autoDispose((ref) async {
  var qiscus = await ref.watch(qiscusProvider.future);
  var roomId = await ref.watch(roomIdProvider.future);

  QChatRoomWithMessages roomData =
      await ref.watch(_roomDataProvider(roomId).future);

  for (var m in roomData.messages) {
    ref.read(messagesProvider.notifier).receive(m);
  }

  qiscus.subscribeChatRoom(roomData.room);
  ref.onDispose(() => qiscus.unsubscribeChatRoom(roomData.room));

  return roomData;
}, name: 'roomProvider');
