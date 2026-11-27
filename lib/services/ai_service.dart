import 'dart:convert';

import 'package:http/http.dart' as http;

/// An AI failure with a message that is safe to show to the user.
class AiException implements Exception {
  final String message;
  final int? statusCode;

  const AiException(this.message, {this.statusCode});

  @override
  String toString() => 'AiException($statusCode): $message';
}

class AiService {
  static bool get isConfigured => apiKey.isNotEmpty;

  static String _messageFor(int status) => switch (status) {
        401 => 'The OpenRouter API key is invalid or expired. Create a new '
            'key at openrouter.ai/keys and restart the app with it.',
        402 => 'The OpenRouter account has run out of credits.',
        403 => 'OpenRouter refused this request (403).',
        429 => 'The free AI model is busy (rate limited). Please wait a '
            'minute and try again.',
        _ when status >= 500 =>
          'The AI service is temporarily unavailable ($status).',
        _ => 'The AI request failed ($status).',
      };

  static const String apiKey =
  String.fromEnvironment('OPENROUTER_API_KEY');

  static Future<String> generateItinerary({
    required String destination,
    required String budget,
    required int days,
    required String interest,
  }) async {
    if (apiKey.isEmpty) {
      throw const AiException(
        'AI is not configured: run the app with '
        '--dart-define=OPENROUTER_API_KEY=your_key',
      );
    }

    final prompt = '''
You are Tripora, an AI travel planning assistant.

Create a personalized travel itinerary for:

Destination: $destination
Budget: $budget
Number of days: $days
Main interest: $interest

Create exactly $days days.

For each day include:

Day 1
Morning:
Afternoon:
Evening:

Day 2
Morning:
Afternoon:
Evening:

Continue until all $days days are completed.

Also provide:

Estimated Total Trip Expense:
- Give an approximate total cost in Indian Rupees (INR).
- Keep the estimate suitable for the selected budget level.

Important rules:
- Do NOT include food or restaurant recommendations.
- Do NOT invent impossible activities.
- Keep the itinerary practical and realistic.
- Consider the selected interest.
- Keep each activity simple and easy to understand.
- Do not include unnecessary explanations.
- Return only the itinerary and estimated expense.
''';

    final url = Uri.parse(
      'https://openrouter.ai/api/v1/chat/completions',
    );

    final requestBody = jsonEncode({
      'model': 'openrouter/free',
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        },
      ],
    });

    for (int attempt = 1; attempt <= 3; attempt++) {
      final http.Response response;
      try {
        response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
                'HTTP-Referer': 'https://tripora.app',
                'X-Title': 'Tripora AI Travel Planner',
              },
              body: requestBody,
            )
            .timeout(const Duration(seconds: 60));
      } catch (e) {
        // Network error or timeout: worth retrying.
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        throw AiException(
          'Cannot reach the AI service. Check your internet connection. ($e)',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().trim().isNotEmpty) {
          return content.toString();
        }
        if (attempt < 3) continue; // empty answer from a free model: retry
        throw const AiException('The AI returned an empty answer. Try again.');
      }

      // Rate limits and server errors are temporary; other 4xx errors
      // (bad key, bad request) are not, so fail immediately.
      if ((response.statusCode == 429 || response.statusCode >= 500) &&
          attempt < 3) {
        await Future.delayed(Duration(seconds: attempt * 2));
        continue;
      }

      throw AiException(
        _messageFor(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    throw const AiException('AI request failed after several attempts.');
  }
}