import '../models/chat_message.dart';
import '../models/tool_definition.dart';
import '../providers/llm_provider.dart';
import '../registry/tool_registry.dart';

/// Current execution status of the agent
enum AgentStatus { idle, streaming, executingTool, completed, error }

class AgentState {
  final String currentText;
  final AgentStatus status;
  final String? activeToolName;
  final String? errorMessage;

  const AgentState({
    this.currentText = '',
    this.status = AgentStatus.idle,
    this.activeToolName,
    this.errorMessage,
  });

  AgentState copyWith({
    String? currentText,
    AgentStatus? status,
    String? activeToolName,
    String? errorMessage,
  }) {
    return AgentState(
      currentText: currentText ?? this.currentText,
      status: status ?? this.status,
      activeToolName: activeToolName,
      errorMessage: errorMessage,
    );
  }
}

class AgentOrchestrator {
  final LlmProvider provider;
  final ToolRegistry toolRegistry;
  final List<ChatMessage> _history = [];

  AgentOrchestrator({
    required this.provider,
    required this.toolRegistry,
  });

  /// Gets a copy of the current conversation history
  List<ChatMessage> get history => List.unmodifiable(_history);

  /// Sends a prompt and emits a Stream with real-time state and text changes
  Stream<AgentState> promptStream(String userPrompt) async* {
    // 1. Add the user's message to the history
    _history.add(ChatMessage(role: MessageRole.user, content: userPrompt));
    
    var currentState = const AgentState(status: AgentStatus.streaming);
    yield currentState;

    try {
      final tools = toolRegistry.getLlmToolSchemas();
      final fullResponseBuffer = StringBuffer();

      // 2. Consume the response stream from the LLM provider
      await for (final chunk in provider.streamResponse(
        history: _history,
        tools: tools.isNotEmpty ? tools.cast<AgentTool>() : null,
      )) {
        fullResponseBuffer.write(chunk);
        currentState = currentState.copyWith(
          currentText: fullResponseBuffer.toString(),
          status: AgentStatus.streaming,
        );
        yield currentState;
      }

      // 3. Save the final response from the assistant in the history
      _history.add(ChatMessage(
        role: MessageRole.assistant,
        content: fullResponseBuffer.toString(),
      ));

      yield currentState.copyWith(status: AgentStatus.completed);
    } catch (e) {
      yield currentState.copyWith(
        status: AgentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clears the conversation history
  void clearHistory() {
    _history.clear();
  }
}