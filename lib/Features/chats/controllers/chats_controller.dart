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
  final DateTime? lastTimestamp;

  const ChatListItem({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
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

    print('[ChatsController] starting stream for uid=$uid');

    // ⚠️ This query requires a composite index in Firestore:
    //    collection: chats | field: participants (Array) + lastTimestamp (Desc)
    //    Firestore will print a link in the logs to create it automatically.
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
    print('[ChatsController] received ${snap.docs.length} chat(s)');

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

      result.add(ChatListItem(
        chatId: doc.id,
        otherUserId: otherId,
        otherUserName: otherName,
        lastMessage: data['lastMessage'] as String? ?? '',
        lastTimestamp: lastTime,
      ));
    }

    _chats = result;
    _isLoading = false;
    _error = null;
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
      print('[ChatsController] fetched name for uid=$uid → $name');
      return name;
    } catch (e) {
      print('[ChatsController] ERROR fetching name for uid=$uid: $e');
      _nameCache[uid] = 'User';
      return 'User';
    }
  }

  // ─── Handle stream errors ─────────────────────────────────────────────────
  void _onError(Object e) {
    print('[ChatsController] stream ERROR: $e');
    // ⚠️ PERMISSION_DENIED → add Firestore rules for chats/:
    //    match /chats/{chatId} { allow read, write: if request.auth != null; }
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
