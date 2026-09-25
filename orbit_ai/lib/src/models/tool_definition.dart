typedef ToolHandler = Future<Object?> Function(Map<String, dynamic> arguments);

class ToolParameter {
  final String name;
  final String type; // 'string', 'number', 'boolean', etc.
  final String description;
  final bool isRequired;
  final List<String>? enumValues;

  const ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.isRequired = true,
    this.enumValues,
  });

  Map<String, dynamic> toJsonSchema() {
    return {
      'type': type,
      'description': description,
      if (enumValues != null) 'enum': enumValues,
    };
  }
}

class AgentTool {
  final String name;
  final String description;
  final List<ToolParameter> parameters;
  final ToolHandler handler;

  const AgentTool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.handler,
  });

  Map<String, dynamic> toLlmSchema() {
    final properties = <String, dynamic>{};
    final requiredParams = <String>[];

    for (final param in parameters) {
      properties[param.name] = param.toJsonSchema();
      if (param.isRequired) requiredParams.add(param.name);
    }

    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': properties,
          if (requiredParams.isNotEmpty) 'required': requiredParams,
        },
      },
    };
  }
}