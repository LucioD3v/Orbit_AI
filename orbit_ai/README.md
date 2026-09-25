# OrbitAI 🚀

OrbitAI is a lightweight, LLM model-agnostic orchestrator specifically designed for Flutter and Dart. It simplifies real-time text streaming, context-aware chat histories, and automatic client-side Function Calling (local tool execution) without blocking the main thread.

## 🌟 Key Features

- **Provider Agnostic:** Seamlessly switch between OpenAI, Alibaba Cloud Qwen, AWS Bedrock, or local models with zero UI or business logic changes.
- **Native Tool Registry:** Register strongly typed functions in Dart and allow the LLM to invoke them securely and autonomously.
- **Non-Blocking Streaming:** Optimized to process real-time text chunks (`promptStream`) and update the UI at 60 FPS without performance hiccups.
- **No Complex Native Dependencies:** Pure Dart code ensuring complete cross-platform stability (iOS, Android, Web, Desktop).

## 📦 Installation

Add `orbit_ai` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  orbit_ai: ^1.0.0
```

## 🚀 Quick Start

### 1. Register a local tool (Function Calling)

```dart
import 'package:orbit_ai/orbit_ai.dart';

final registry = ToolRegistry();

registry.register(
  AgentTool(
    name: 'get_current_weather',
    description: 'Gets the current weather for a specific location.',
    parameters: const [
      ToolParameter(
        name: 'location',
        type: 'string',
        description: 'City or region, e.g. Mexico City',
      ),
    ],
    handler: (args) async {
      final location = args['location'];
      // Execute your local business logic or platform APIs here
      return {'location': location, 'temp': '24°C', 'condition': 'Sunny'};
    },
  ),
);
```

### 2. Choose your LLM Provider (OpenAI or Alibaba Cloud Qwen)

#### Option A: OpenAI Provider
```dart
final provider = OpenAiProvider(
  apiKey: 'YOUR_OPENAI_API_KEY',
  model: 'gpt-4o',
);
```

#### Option B: Alibaba Cloud Qwen Provider
```dart
final provider = QwenProvider(
  apiKey: 'YOUR_DASHSCOPE_API_KEY',
  model: 'qwen-plus',
);
```

### 3. Initialize the Orchestrator and stream responses

```dart
final orchestrator = AgentOrchestrator(
  provider: provider,
  toolRegistry: registry,
);

// Listen to real-time response chunks and state updates
await for (final state in orchestrator.promptStream('What is the weather like in Mexico City?')) {
  print('Status: ${state.status.name}');
  print('Current Text: ${state.currentText}');
}
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.