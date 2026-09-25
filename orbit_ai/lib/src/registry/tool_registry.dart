import 'dart:convert';
import '../models/tool_definition.dart';

class ToolExecutionResult {
  final String toolName;
  final bool isSuccess;
  final Object? output;
  final String? errorMessage;

  ToolExecutionResult.success(this.toolName, this.output)
      : isSuccess = true,
        errorMessage = null;

  ToolExecutionResult.failure(this.toolName, this.errorMessage)
      : isSuccess = false,
        output = null;

  String toLlmContextMessage() {
    if (!isSuccess) {
      return jsonEncode({'error': true, 'tool': toolName, 'message': errorMessage});
    }
    return output is String ? output as String : jsonEncode(output);
  }
}

class ToolRegistry {
  final Map<String, AgentTool> _tools = {};

  void register(AgentTool tool) {
    if (_tools.containsKey(tool.name)) {
      throw ArgumentError('The tool "${tool.name}" is already registered..');
    }
    _tools[tool.name] = tool;
  }

  List<Map<String, dynamic>> getLlmToolSchemas() {
    return _tools.values.map((tool) => tool.toLlmSchema()).toList();
  }

  Future<ToolExecutionResult> executeCall({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final tool = _tools[toolName];
    if (tool == null) {
      return ToolExecutionResult.failure(toolName, 'The tool does not exist.');
    }

    try {
      final result = await tool.handler(arguments);
      return ToolExecutionResult.success(toolName, result);
    } catch (e) {
      return ToolExecutionResult.failure(toolName, 'Exception: $e');
    }
  }
}