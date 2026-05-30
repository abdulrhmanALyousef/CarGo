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
    debugPrint('[Chat] chatId=$chatId | currentUser=$currentUserId | otherUser=$otherUserId');
    _ensureChatExists();
  }

  // ─── Messages stream ──────────────────────────────────────────────────────
  // Ascending order so oldest messages appear at the top and newest at the
  // bottom — the scroll-to-bottom logic keeps the latest message visible.
  Stream<QuerySnapshot<Map<String, dynamic>>> get messagesStream {
    debugPrint('[Chat] subscribing to stream — chats/$chatId/messages');
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // ─── Ensure chat document exists ──────────────────────────────────────────
  Future<void> _ensureChatExists() async {
    debugPrint('[Chat] _ensureChatExists — chats/$chatId');
    try {
      final docRef = _firestore.collection('chats').doc(chatId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'chatId': chatId,
          'participants': [currentUserId, otherUserId],
          'lastMessage': '',
          'lastMessageType': 'text',
          'lastTimestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _chatReady = true;
      debugPrint('[Chat] chat document ready');
    } catch (e) {
      debugPrint('[Chat] ERROR creating chat document: $e');
    }
  }

  // ─── Send location message ──────────────────────────────────────────────
  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    if (_isSending) return;

    if (!_chatReady) await _ensureChatExists();

    _isSending = true;
    notifyListeners();

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'receiverId': otherUserId,
        'type': 'location',
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'text': '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await _firestore.collection('chats').doc(chatId).set(
        {
          'lastMessage': 'Location',
          'lastMessageType': 'location',
          'lastTimestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint('[Chat] ERROR sending location: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Send message ─────────────────────────────────────────────────────────
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Wait for the chat document to be ready before writing.
    if (!_chatReady) {
      debugPrint('[Chat] chat not ready yet — waiting for _ensureChatExists');
      await _ensureChatExists();
    }

    debugPrint('[Chat] sending message: "$text"');
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
      debugPrint('[Chat] message written — id=${msgRef.id}');

      // ── Step 2: update chat metadata (set+merge is safe on new docs) ─────
      await _firestore.collection('chats').doc(chatId).set(
        {
          'lastMessage': text,
          'lastMessageType': 'text',
          'lastTimestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('[Chat] chat metadata updated');

      _scrollToBottom();
    } catch (e) {
      debugPrint('[Chat] ERROR sending message: $e');
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
    debugPrint('[Chat] markMessagesRead — chatId=$chatId');
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
      debugPrint('[Chat] marked ${unread.docs.length} messages as read');
    } catch (e) {
      debugPrint('[Chat] ERROR marking messages read: $e');
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
