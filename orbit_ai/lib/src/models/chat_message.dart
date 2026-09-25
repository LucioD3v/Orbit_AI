enum MessageRole { user, assistant, system, tool }

class ChatMessage {
  final MessageRole role;
  final String content;
  final String? toolCallId;
  final String? toolName;

  const ChatMessage({
    required this.role,
    required this.content,
    this.toolCallId,
    this.toolName,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'content': content,
      if (toolCallId != null) 'tool_call_id': toolCallId,
      if (toolName != null) 'name': toolName,
    };
  }
}