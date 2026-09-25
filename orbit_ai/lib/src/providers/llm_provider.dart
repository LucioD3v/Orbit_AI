import '../models/chat_message.dart';
import '../models/tool_definition.dart';

abstract class LlmProvider {
  /// Send a message and wait for the full response.
  Future<String> generateResponse({
    required List<ChatMessage> history,
    List<AgentTool>? tools,
  });

  /// Send a message and stream the response in real-time (Streaming)
  Stream<String> streamResponse({
    required List<ChatMessage> history,
    List<AgentTool>? tools,
  });
}