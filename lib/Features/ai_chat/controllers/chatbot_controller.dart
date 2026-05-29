import 'package:flutter/material.dart';
import 'package:cargo/Features/ai_chat/models/chat_message.dart';
import 'package:cargo/Features/ai_chat/services/ai_service.dart';

class ChatbotController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<AiChatMessage> _messages = [];
  List<AiChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    textController.clear();
    _error = null;

    // Capture history BEFORE adding new message
    final history = List<AiChatMessage>.from(_messages);

    // Add user message
    _messages.add(AiChatMessage(role: 'user', text: trimmed));
    _isLoading = true;
    notifyListeners();
    _scrollToBottom();

    try {
      final response = await AiService.sendMessage(trimmed, history);

      if (response.type == 'car_results' && response.cars.isNotEmpty) {
        // Add text message first if there's a reply
        if (response.reply.isNotEmpty) {
          _messages.add(AiChatMessage(
            role: 'assistant',
            text: response.reply,
          ));
        }
        // Add car results as a separate message
        _messages.add(AiChatMessage(
          role: 'assistant',
          text: response.reply,
          type: MessageType.carResults,
          cars: response.cars,
        ));
      } else {
        _messages.add(AiChatMessage(
          role: 'assistant',
          text: response.reply,
        ));
      }
    } catch (e) {
      debugPrint('🔴 AI Chat Error: $e');
      _error = 'Failed to get response. Please try again.';
      _messages.removeLast();
    } finally {
      _isLoading = false;
      notifyListeners();
      _scrollToBottom();
    }
  }

  void sendQuickMessage(String text) => sendMessage(text);

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
