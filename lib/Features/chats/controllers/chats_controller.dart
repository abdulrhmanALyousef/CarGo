import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';

// ── Data class for a single chat list item ────────────────────────────────────
class ChatListItem {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final String lastMessageType;
  final DateTime? lastTimestamp;

  const ChatListItem({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastTimestamp,
  });
}

// ── Controller ────────────────────────────────────────────────────────────────
class ChatsController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ChatListItem> _chats = [];
  bool _isLoading = true;
  String? _error;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  // Cache userId → fullName so we don't re-fetch on every stream update.
  final Map<String, String> _nameCache = {};

  List<ChatListItem> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatsController() {
    _start();
  }

  // ─── Start real-time stream ───────────────────────────────────────────────
  void _start() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      _error = 'Not logged in.';
      notifyListeners();
      return;
    }

    print('[ChatsList] starting stream for uid=$uid');

    _sub = _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .listen(
          (snap) => _onData(snap, uid),
          onError: _onError,
        );
  }

  // ─── Handle stream events ─────────────────────────────────────────────────
  Future<void> _onData(
    QuerySnapshot<Map<String, dynamic>> snap,
    String currentUserId,
  ) async {
    print('[ChatsList] received ${snap.docs.length} chat(s)');

    final result = <ChatListItem>[];

    for (final doc in snap.docs) {
      final data = doc.data();

      // Determine the other participant.
      final participants = List<String>.from(data['participants'] ?? []);
      final otherId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      final otherName = await _fetchName(otherId);

      DateTime? lastTime;
      final raw = data['lastTimestamp'];
      if (raw is Timestamp) lastTime = raw.toDate();

      var lastMsg = data['lastMessage'] as String? ?? '';
      var lastType = data['lastMessageType'] as String? ?? 'text';

      // Self-heal: if lastMessage is empty, fetch the actual last message
      // from the subcollection. This repairs docs corrupted by the old
      // _ensureChatExists that blanked lastMessage on every open.
      if (lastMsg.isEmpty) {
        try {
          final msgSnap = await _db
              .collection('chats')
              .doc(doc.id)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (msgSnap.docs.isNotEmpty) {
            final msgData = msgSnap.docs.first.data();
            final msgType = msgData['type'] as String? ?? 'text';

            if (msgType == 'location') {
              lastMsg = 'Location';
              lastType = 'location';
            } else {
              lastMsg = msgData['text'] as String? ?? '';
              lastType = 'text';
            }

            // Also repair the chat document so this doesn't repeat.
            doc.reference.set({
              'lastMessage': lastMsg,
              'lastMessageType': lastType,
            }, SetOptions(merge: true));
          }
        } catch (_) {
          // Non-critical — preview just stays empty this time.
        }
      }

      // Infer type for legacy docs that stored '📍 Location' before
      // lastMessageType was added.
      if (lastType == 'text' && lastMsg == '\u{1F4CD} Location') {
        lastType = 'location';
      }

      print('[ChatsList] chat=${doc.id} lastMessage="$lastMsg" lastMessageType=$lastType');

      result.add(ChatListItem(
        chatId: doc.id,
        otherUserId: otherId,
        otherUserName: otherName,
        lastMessage: lastMsg,
        lastMessageType: lastType,
        lastTimestamp: lastTime,
      ));
    }

    _chats = result;
    _isLoading = false;
    _error = null;
    print('[ChatsList] rebuilt with ${result.length} chats');
    notifyListeners();
  }

  // ─── Fetch (and cache) a user's display name ──────────────────────────────
  Future<String> _fetchName(String uid) async {
    if (uid.isEmpty) return 'Unknown';
    if (_nameCache.containsKey(uid)) return _nameCache[uid]!;

    try {
      final data = await FirebaseService().getUserData(uid: uid);
      final name = data?['fullName'] as String? ?? 'User';
      _nameCache[uid] = name;
      return name;
    } catch (_) {
      _nameCache[uid] = 'User';
      return 'User';
    }
  }

  // ─── Handle stream errors ─────────────────────────────────────────────────
  void _onError(Object e) {
    print('[ChatsList] stream ERROR: $e');
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
