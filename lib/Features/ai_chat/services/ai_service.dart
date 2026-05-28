import 'package:cloud_functions/cloud_functions.dart';
import 'package:cargo/Features/ai_chat/models/chat_message.dart';
import 'package:cargo/models/car_model.dart';

class AiChatResponse {
  final String type; // 'text' or 'car_results'
  final String reply;
  final List<Car> cars;

  AiChatResponse({required this.type, required this.reply, required this.cars});
}

class AiService {
  static final _callable = FirebaseFunctions.instanceFor(region: 'us-central1')
      .httpsCallable('geminiChat');

  static Future<AiChatResponse> sendMessage(
    String prompt,
    List<AiChatMessage> history,
  ) async {
    final historyData = history
        .where((m) => m.type == MessageType.text)
        .map((m) => m.toHistory())
        .toList();

    final result = await _callable.call<Map<String, dynamic>>({
      'prompt': prompt,
      'history': historyData,
    });

    final data = result.data;
    final type = data['type'] as String? ?? 'text';
    final reply = data['reply'] as String? ?? '';
    final carsRaw = data['cars'] as List<dynamic>? ?? [];

    final cars = carsRaw.map((c) {
      final map = Map<String, dynamic>.from(c as Map);
      return Car.fromJson(map);
    }).toList();

    return AiChatResponse(type: type, reply: reply, cars: cars);
  }
}
