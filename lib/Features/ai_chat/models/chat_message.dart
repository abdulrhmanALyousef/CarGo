import 'package:cargo/models/car_model.dart';

enum MessageType { text, carResults, loading }

class AiChatMessage {
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final List<Car> cars;

  AiChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.type = MessageType.text,
    this.cars = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';

  Map<String, String> toHistory() => {'role': role, 'text': text};
}
