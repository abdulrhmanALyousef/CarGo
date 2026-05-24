import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/chats/controllers/chats_controller.dart';
import 'package:cargo/Features/chats/presentation/chat_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatsController(),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<ChatsController>();

          return Scaffold(
            backgroundColor: LightColors.backgroundColor,
            appBar: AppBar(
              title: const Text('Chats'),
            ),
            body: _buildBody(context, ctrl),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatsController ctrl) {
    // ── Loading ───────────────────────────────────────────────────────────────
    if (ctrl.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LightColors.primaryColor),
      );
    }

    // ── Error ─────────────────────────────────────────────────────────────────
    if (ctrl.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load chats.\n${ctrl.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.red),
          ),
        ),
      );
    }

    // ── Empty ─────────────────────────────────────────────────────────────────
    if (ctrl.chats.isEmpty) {
      return Center(
        child: Text(
          'No chats yet.\nStart a conversation from a car listing.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: LightColors.textColor.withOpacity(0.4),
          ),
        ),
      );
    }

    // ── Chat list ─────────────────────────────────────────────────────────────
    return ListView.separated(
      itemCount: ctrl.chats.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 72,
        color: LightColors.textColor.withOpacity(0.08),
      ),
      itemBuilder: (context, index) {
        final item = ctrl.chats[index];
        return _ChatTile(item: item);
      },
    );
  }
}

// ── Chat list tile ────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatListItem item;
  const _ChatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: item.chatId,
              currentUserId: currentUserId,
              otherUserId: item.otherUserId,
              otherUserName: item.otherUserName,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ───────────────────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LightColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item.otherUserName.isNotEmpty
                      ? item.otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: LightColors.primaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Name + last message ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.otherUserName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: LightColors.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  _buildLastMessagePreview(item),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Timestamp ─────────────────────────────────────────────────────
            if (item.lastTimestamp != null)
              Text(
                _formatTime(item.lastTimestamp!),
                style: TextStyle(
                  fontSize: 11,
                  color: LightColors.textColor.withOpacity(0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastMessagePreview(ChatListItem item) {
    if (item.lastMessage.isEmpty) {
      return Text(
        'No messages yet',
        style: TextStyle(
          fontSize: 13,
          color: LightColors.textColor.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final previewColor = LightColors.textColor.withOpacity(0.5);

    switch (item.lastMessageType) {
      case 'location':
        return Row(
          children: [
            Icon(Icons.location_on, size: 15, color: previewColor),
            const SizedBox(width: 4),
            Text(
              'Location',
              style: TextStyle(fontSize: 13, color: previewColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case 'image':
        return Row(
          children: [
            Icon(Icons.photo_camera, size: 15, color: previewColor),
            const SizedBox(width: 4),
            Text(
              'Photo',
              style: TextStyle(fontSize: 13, color: previewColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case 'video':
        return Row(
          children: [
            Icon(Icons.videocam, size: 15, color: previewColor),
            const SizedBox(width: 4),
            Text(
              'Video',
              style: TextStyle(fontSize: 13, color: previewColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case 'audio':
        return Row(
          children: [
            Icon(Icons.mic, size: 15, color: previewColor),
            const SizedBox(width: 4),
            Text(
              'Voice message',
              style: TextStyle(fontSize: 13, color: previewColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      default:
        return Text(
          item.lastMessage,
          style: TextStyle(fontSize: 13, color: previewColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    if (today.difference(msgDay).inDays == 1) return 'Yesterday';

    return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
  }
}
