import 'package:http/http.dart' as http;
import 'dart:convert';

class Book {
  final String title;
  final String author;
  final String description;
  final String genre;
  final int? yearPublished;

  Book({
    required this.title,
    required this.author,
    required this.description,
    required this.genre,
    this.yearPublished,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    var yearPublished = json['yearPublished'];
    // Handle yearPublished that might come as string or int
    int? parsedYear;
    if (yearPublished != null) {
      if (yearPublished is int) {
        parsedYear = yearPublished;
      } else if (yearPublished is String) {
        parsedYear = int.tryParse(yearPublished);
      }
    }

    return Book(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      genre: json['genre'] ?? '',
      yearPublished: parsedYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'genre': genre,
      'yearPublished': yearPublished,
    };
  }
}

class BookService {
  static const String _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey;

  BookService(this._apiKey);

  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await http.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a book database expert. Return ONLY a JSON object with a 'books' array. 
              Each book in the array must have exactly these fields:
              {
                "title": "Book Title",
                "author": "Author Name",
                "description": "Book description",
                "genre": "Book genre",
                "yearPublished": 2024
              }''',
            },
            {
              'role': 'user',
              'content': 'Find books matching: $query',
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
          'response_format': { 'type': 'json_object' },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('OpenAI Response: $content'); // Debug log
        
        final parsedContent = jsonDecode(content);
        if (!parsedContent.containsKey('books')) {
          throw Exception('Invalid response format: missing books array');
        }
        
        final booksJson = parsedContent['books'] as List;
        return booksJson.map((book) {
          if (book is! Map<String, dynamic>) {
            throw Exception('Invalid book format: $book');
          }
          return Book.fromJson(book);
        }).toList();
      } else {
        print('API Error Response: ${response.body}'); // Debug log
        throw Exception('Failed to search books: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error searching books: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log
      throw Exception('Error searching books: $e');
    }
  }

  Future<List<Book>> getRecommendations(Book book) async {
    try {
      final response = await http.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a book recommendation expert. Return ONLY a JSON object with a 'books' array. 
              Each book in the array must have exactly these fields:
              {
                "title": "Book Title",
                "author": "Author Name",
                "description": "Book description",
                "genre": "Book genre",
                "yearPublished": 2024
              }''',
            },
            {
              'role': 'user',
              'content': 'Recommend books similar to: ${book.title} by ${book.author} (${book.genre})',
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
          'response_format': { 'type': 'json_object' },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('OpenAI Response: $content'); // Debug log
        
        final parsedContent = jsonDecode(content);
        if (!parsedContent.containsKey('books')) {
          throw Exception('Invalid response format: missing books array');
        }
        
        final booksJson = parsedContent['books'] as List;
        return booksJson.map((book) {
          if (book is! Map<String, dynamic>) {
            throw Exception('Invalid book format: $book');
          }
          return Book.fromJson(book);
        }).toList();
      } else {
        print('API Error Response: ${response.body}'); // Debug log
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error getting recommendations: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log
      throw Exception('Error getting recommendations: $e');
    }
  }
} 