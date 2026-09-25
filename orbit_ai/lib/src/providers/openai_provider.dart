import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/tool_definition.dart';
import 'llm_provider.dart';

class OpenAiProvider implements LlmProvider {
  final String apiKey;
  final String model;

  OpenAiProvider({
    required this.apiKey,
    this.model = 'gpt-4o',
  });

  @override
  Future<String> generateResponse({
    required List<ChatMessage> history,
    List<AgentTool>? tools,
  }) async {
    var fullText = '';
    await for (var chunk in streamResponse(history: history, tools: tools)) {
      fullText += chunk;
    }
    return fullText;
  }

  @override
  Stream<String> streamResponse({
    required List<ChatMessage> history,
    List<AgentTool>? tools,
  }) async* {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final body = {
      'model': model,
      'messages': history.map((m) => m.toJson()).toList(),
      'stream': true,
      if (tools != null && tools.isNotEmpty)
        'tools': tools.map((t) => t.toLlmSchema()).toList(),
    };

    final request = http.Request('POST', url)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      })
      ..body = jsonEncode(body);

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('Error OpenAI [${response.statusCode}]: ${response.reasonPhrase}');
    }

    // Process the SSE (Server-Sent Events) stream line by line
    await for (var line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;

        try {
          final decoded = jsonDecode(data);
          final choices = decoded['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map?;
            if (delta != null && delta.containsKey('content')) {
              final content = delta['content'] as String?;
              if (content != null) yield content;
            }
          }
        } catch (_) {
          // Ignore empty chunks or network keep-alives
        }
      }
    }
  }
}