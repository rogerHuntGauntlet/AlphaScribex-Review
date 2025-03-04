import 'dart:convert';
import 'package:http/http.dart' as http;

class AIAnalysisService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey;

  AIAnalysisService(this._apiKey);

  Future<Map<String, dynamic>> analyzeText(String text, int currentLevel) async {
    final prompt = _buildPrompt(text, currentLevel);
    
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a writing coach analyzing text for quality and correctness. Provide detailed feedback and scoring for improvement.'
          },
          {
            'role': 'user',
            'content': prompt
          }
        ],
        'temperature': 0.7
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final analysis = data['choices'][0]['message']['content'];
      return _parseAnalysis(analysis);
    } else {
      throw Exception('Failed to analyze text: ${response.body}');
    }
  }

  String _buildPrompt(String text, int currentLevel) {
    switch (currentLevel) {
      case 0:
        return '''
Analyze the following text for sentence quality. The user needs to write 5 perfect sentences.
A perfect sentence should be:
1. Grammatically correct
2. Clear and concise
3. Well-structured
4. Meaningful and complete

Text to analyze:
$text

Please provide:
1. Number of valid sentences found
2. Analysis of each sentence (numbered)
3. Score for each sentence (0-10)
4. Whether each sentence meets the "perfect" criteria
5. Suggestions for improvement where needed
6. Overall progress towards the goal of 5 perfect sentences

Format the response as JSON with the following structure:
{
  "validSentences": number,
  "sentenceAnalysis": [
    {
      "sentence": "text",
      "score": number,
      "isPerfect": boolean,
      "feedback": "detailed feedback",
      "suggestions": "improvement suggestions"
    }
  ],
  "progress": "X/5 perfect sentences achieved",
  "nextSteps": "what the user should focus on next"
}
''';

      case 1:
        return '''
Analyze the following text for paragraph quality. The user needs to write 5 perfect paragraphs.
A perfect paragraph should:
1. Have a clear topic sentence
2. Contain supporting sentences
3. Maintain coherence and unity
4. End with a proper conclusion
5. Have smooth transitions

Text to analyze:
$text

Please provide:
1. Number of valid paragraphs found
2. Analysis of each paragraph (numbered)
3. Score for each paragraph (0-10)
4. Whether each paragraph meets the "perfect" criteria
5. Suggestions for improvement
6. Overall progress towards the goal of 5 perfect paragraphs

Format the response as JSON with the following structure:
{
  "validParagraphs": number,
  "paragraphAnalysis": [
    {
      "paragraph": "text",
      "score": number,
      "isPerfect": boolean,
      "feedback": "detailed feedback",
      "suggestions": "improvement suggestions"
    }
  ],
  "progress": "X/5 perfect paragraphs achieved",
  "nextSteps": "what the user should focus on next"
}
''';

      case 2:
        return '''
Analyze the following text for page quality. The user needs to write 5 perfect pages.
A perfect page should:
1. Have a clear theme or topic
2. Contain well-structured paragraphs
3. Maintain logical flow and coherence
4. Have proper transitions between paragraphs
5. Be approximately 250-300 words

Text to analyze:
$text

Please provide:
1. Number of valid pages found
2. Analysis of each page (numbered)
3. Score for each page (0-10)
4. Whether each page meets the "perfect" criteria
5. Suggestions for improvement
6. Overall progress towards the goal of 5 perfect pages

Format the response as JSON with the following structure:
{
  "validPages": number,
  "pageAnalysis": [
    {
      "page": "text",
      "score": number,
      "isPerfect": boolean,
      "feedback": "detailed feedback",
      "suggestions": "improvement suggestions"
    }
  ],
  "progress": "X/5 perfect pages achieved",
  "nextSteps": "what the user should focus on next"
}
''';

      default:
        return 'Analyze the following text for overall writing quality:\n\n$text';
    }
  }

  Map<String, dynamic> _parseAnalysis(String analysis) {
    try {
      return jsonDecode(analysis);
    } catch (e) {
      return {
        'error': 'Failed to parse analysis',
        'rawAnalysis': analysis,
      };
    }
  }
} 