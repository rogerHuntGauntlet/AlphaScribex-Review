import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey; // This should be securely stored and retrieved

  OpenAIService(this._apiKey);

  Future<Map<String, String>> generateProjectDetails(String voiceInput) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful writing assistant. Given a voice description of a writing project, create a concise title and description. Respond in JSON format with "title" and "description" fields.',
            },
            {
              'role': 'user',
              'content': voiceInput,
            },
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        final projectDetails = jsonDecode(content);
        
        return {
          'title': projectDetails['title'] ?? 'Untitled Project',
          'description': projectDetails['description'] ?? '',
        };
      } else {
        throw Exception('Failed to generate project details');
      }
    } catch (e) {
      throw Exception('Error generating project details: $e');
    }
  }
} 