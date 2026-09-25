import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_ai/orbit_ai.dart';

/// Mock provider for testing the orchestrator without consuming API credits.
class MockLlmProvider implements LlmProvider {
  final List<String> chunksToYield;

  MockLlmProvider({required this.chunksToYield});

  @override
  Future<String> generateResponse({
    required List<ChatMessage> history,
    List<AgentTool>? tools,
  }) async {
    return chunksToYield.join();
  }

  @override
  Stream<String> streamResponse({
    required List<ChatMessage> history,
    List<AgentTool>? tools,
  }) async* {
    for (final chunk in chunksToYield) {
      await Future.delayed(const Duration(milliseconds: 5));
      yield chunk;
    }
  }
}

void main() {
  group('ToolRegistry Unit Tests', () {
    test('Should register and execute a tool successfully', () async {
      final registry = ToolRegistry();

      registry.register(
        AgentTool(
          name: 'get_sum',
          description: 'Sums two numbers',
          parameters: const [
            ToolParameter(name: 'a', type: 'number', description: 'First number'),
            ToolParameter(name: 'b', type: 'number', description: 'Second number'),
          ],
          handler: (args) async {
            final a = args['a'] as num;
            final b = args['b'] as num;
            return {'result': a + b};
          },
        ),
      );

      final result = await registry.executeCall(
        toolName: 'get_sum',
        arguments: {'a': 10, 'b': 15},
      );

      expect(result.isSuccess, isTrue);
      expect(result.toolName, equals('get_sum'));
      expect(result.output, equals({'result': 25}));
    });

    test('Should throw ArgumentError on duplicate tool registration', () {
      final registry = ToolRegistry();
      final tool = AgentTool(
        name: 'test_tool',
        description: 'Test',
        parameters: const [],
        handler: (args) async => null,
      );

      registry.register(tool);
      
      // Attempting to register the same tool should throw an error.
      expect(() => registry.register(tool), throwsArgumentError);
    });

    test('Should return failure when executing a non-existent tool', () async {
      final registry = ToolRegistry();
      final result = await registry.executeCall(
        toolName: 'ghost_tool',
        arguments: {},
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('does not exist'));
    });
  });

  group('AgentOrchestrator Unit Tests', () {
    test('Should stream response chunks and build history correctly', () async {
      final mockProvider = MockLlmProvider(chunksToYield: ['Hello', ' from', ' OrbitAI!']);
      final registry = ToolRegistry();

      final orchestrator = AgentOrchestrator(
        provider: mockProvider,
        toolRegistry: registry,
      );

      final states = <AgentState>[];
      
      await for (final state in orchestrator.promptStream('Say hello')) {
        states.add(state);
      }

      // Assertions
      expect(states,isNotEmpty);
      expect(states.last.status, equals(AgentStatus.completed));
      expect(states.last.currentText, equals('Hello from OrbitAI!'));
      
      // The history should contain the user's message and the assistant's response
      expect(orchestrator.history.length, equals(2));
      expect(orchestrator.history[0].role, equals(MessageRole.user));
      expect(orchestrator.history[1].role, equals(MessageRole.assistant));
    });
  });
}