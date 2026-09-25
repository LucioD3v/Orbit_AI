import 'package:orbit_ai/orbit_ai.dart';

void main() async {
  print('--- Testing the OrbitAI Demo ---');

  // 1. Register a local tool (Function Calling)
  final registry = ToolRegistry();
  registry.register(
    AgentTool(
      name: 'get_current_weather',
      description: 'Gets the current weather for a location.',
      parameters: const [
        ToolParameter(
          name: 'location',
          type: 'string',
          description: 'City or region, e.g., Mexico City',
        ),
      ],
      handler: (args) async {
        final location = args['location'];
        return {'location': location, 'temp': '24°C', 'condition': 'Soleado'};
      },
    ),
  );

  // 2. Configure the provider (you can use OpenAI or Qwen from Alibaba Cloud)
  final provider = OpenAiProvider(
    apiKey: 'tu-api-key-aqui',
    model: 'gpt-4o',
  );

  // 3. Initialize the Orchestrator
  final orchestrator = AgentOrchestrator(
    provider: provider,
    toolRegistry: registry,
  );

  print('Orchestrator initialized successfully with ToolRegistry.');
  print('Ready to process prompts and stream at 60 FPS.');
}