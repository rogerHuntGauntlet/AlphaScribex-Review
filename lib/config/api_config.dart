import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIConfig {
  static String get openAIKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key == 'your_api_key_here') {
      throw Exception('OpenAI API key not found. Please add your API key to the .env file.');
    }
    return key;
  }
} 