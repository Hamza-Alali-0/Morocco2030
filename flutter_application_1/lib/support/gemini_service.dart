import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final String apiKey;
  GenerativeModel? _model;

  GeminiService() {
    apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }
    _initModel();
  }

  void _initModel() {
    _model = GenerativeModel(
      // Try this model name instead
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
    );
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text != null) {
        return response.text!;
      } else {
        return "I couldn't generate a response. Please try again.";
      }
    } catch (e) {
      return "Sorry, I encountered an error: ${e.toString()}";
    }
  }
}
