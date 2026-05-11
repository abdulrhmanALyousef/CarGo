import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatController extends ChangeNotifier {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool _isSending = false;
  bool get isSending => _isSending;

  // Tracks whether the chat document setup has completed.
  bool _chatReady = false;

  ChatController({
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  }) {
    print('[Chat] chatId=$chatId | currentUser=$currentUserId | otherUser=$otherUserId');
    _ensureChatExists();
  }

  // ─── Messages stream ──────────────────────────────────────────────────────
  // Ascending order so oldest messages appear at the top and newest at the
  // bottom — the scroll-to-bottom logic keeps the latest message visible.
  Stream<QuerySnapshot<Map<String, dynamic>>> get messagesStream {
    print('[Chat] subscribing to stream — chats/$chatId/messages');
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // ─── Ensure chat document exists ──────────────────────────────────────────
  // Uses set() with merge so it is safe whether the doc exists or not.
  Future<void> _ensureChatExists() async {
    print('[Chat] _ensureChatExists — chats/$chatId');
    try {
      await _firestore.collection('chats').doc(chatId).set(
        {
          'chatId': chatId,
          'participants': [currentUserId, otherUserId],
          'lastMessage': '',
          'lastTimestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // no-op if doc already exists
      );
      _chatReady = true;
      print('[Chat] chat document ready');
    } catch (e) {
      print('[Chat] ERROR creating chat document: $e');
      // ⚠️ If this prints PERMISSION_DENIED, add Firestore rules — see bottom
      // of this file for the required rules.
    }
  }

  // ─── Send message ─────────────────────────────────────────────────────────
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Wait for the chat document to be ready before writing.
    if (!_chatReady) {
      print('[Chat] chat not ready yet — waiting for _ensureChatExists');
      await _ensureChatExists();
    }

    print('[Chat] sending message: "$text"');
    messageController.clear();
    _isSending = true;
    notifyListeners();

    try {
      // ── Step 1: write the message ────────────────────────────────────────
      final msgRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'receiverId': otherUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      print('[Chat] message written — id=${msgRef.id}');

      // ── Step 2: update chat metadata (set+merge is safe on new docs) ─────
      await _firestore.collection('chats').doc(chatId).set(
        {
          'lastMessage': text,
          'lastTimestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('[Chat] chat metadata updated');

      _scrollToBottom();
    } catch (e) {
      print('[Chat] ERROR sending message: $e');
      // ⚠️ PERMISSION_DENIED here means Firestore rules block writes to
      //    chats/{chatId}/messages — see rules note at bottom of this file.
      messageController.text = text; // restore so the user can retry
      notifyListeners();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Mark incoming messages as read ──────────────────────────────────────
  Future<void> markMessagesRead() async {
    print('[Chat] markMessagesRead — chatId=$chatId');
    try {
      final unread = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unread.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      print('[Chat] marked ${unread.docs.length} messages as read');
    } catch (e) {
      print('[Chat] ERROR marking messages read: $e');
    }
  }

  // ─── Scroll ───────────────────────────────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}

// =============================================================================
// REQUIRED FIRESTORE SECURITY RULES
// =============================================================================
// Add these in Firebase Console → Firestore Database → Rules.
// Without them every read/write to chats/ will fail with PERMISSION_DENIED.
//
//   match /chats/{chatId} {
//     allow read, write: if request.auth != null;
//
//     match /messages/{messageId} {
//       allow read, write: if request.auth != null;
//     }
//   }
// =============================================================================
