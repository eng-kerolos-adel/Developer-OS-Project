import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Google Gemini API - مجاني تماماً
  // الحد المجاني: 15 request/minute, 1500 request/day
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-3-flash-preview'; // أسرع موديل مجاني

  final String apiKey;

  AIService({required this.apiKey});

  String get _generateUrl =>
      '$_baseUrl/$_model:generateContent?key=$apiKey';

  // =====================
  // Generate Project Details
  // =====================
  Future<Map<String, dynamic>> generateProjectDetails({
    required String projectName,
    String? specialization,
    List<String>? existingTechs,
  }) async {
    final prompt = '''
You are a software project planning expert.
Developer specialization: ${specialization ?? 'Full Stack Developer'}
${existingTechs != null && existingTechs.isNotEmpty ? 'Developer skills: ${existingTechs.join(', ')}' : ''}

Generate project details for a project named: "$projectName"

Respond with ONLY valid JSON, no markdown, no extra text, no code blocks:
{
  "description": "2 sentence professional description in English",
  "tech_stack": ["tech1", "tech2", "tech3", "tech4"],
  "project_type": "one of: Web Application, Mobile App, Desktop App, API / Backend, Library / SDK, CLI Tool, Game, Data Pipeline, ML Model, Full Stack",
  "target_platform": "one of: Web (Browser), iOS, Android, Cross-platform, Windows, macOS, Linux, Cloud (Serverless)",
  "estimated_weeks": 8,
  "key_features": ["feature1", "feature2", "feature3"],
  "tips": ["tip1", "tip2"]
}
''';

    final response = await http.post(
      Uri.parse(_generateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }

    final data = json.decode(response.body);
    final content = data['candidates'][0]['content']['parts'][0]['text'] as String;

    // تنظيف الـ JSON
    String cleaned = content
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // لو في نص قبل الـ JSON، نجيب بس الـ JSON
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1) {
      cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
    }

    return json.decode(cleaned);
  }

  // =====================
  // Generate Task Description
  // =====================
  Future<String> generateTaskDescription(
      String taskTitle, String projectName) async {
    final prompt =
        'Write a one-sentence task description for: "$taskTitle" in project "$projectName". English only. No quotes. No extra text.';

    final response = await http.post(
      Uri.parse(_generateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.5,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode != 200) return '';
    final data = json.decode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }


  // =====================
  // Generate Bio
  // =====================
  Future<String> generateBio(
      String prompt) async {

    final response = await http.post(
      Uri.parse(_generateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': '$prompt'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.5,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode != 200) return '';
    final data = json.decode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  // =====================
  // Generate Bio
  // =====================
  Future<String> generateReadme(
      String prompt) async {

    final response = await http.post(
      Uri.parse(_generateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': '$prompt'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.5,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode != 200) return '';
    final data = json.decode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  // =====================
  // Generate Journal Summary
  // =====================
  Future<String> generateJournalSummary(String content) async {
    final prompt =
        'Summarize this developer journal entry in 2 sentences. Keep it professional and concise:\n\n$content';

    final response = await http.post(
      Uri.parse(_generateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.5,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode != 200) return content;
    final data = json.decode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  // =====================
  // Generate Code Explanation
  // =====================
  Future<String> explainCode(String code, String language) async {
    final prompt =
        'Explain this $language code briefly in 2-3 sentences. Be concise and technical:\n\n$code';

    final response = await http.post(
      Uri.parse(_generateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode != 200) return '';
    final data = json.decode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  // =====================
  // Generate Interview Questions
  // =====================
  Future<List<String>> generateInterviewQuestions({
    required String position,
    required String company,
    int count = 5,
  }) async {
    final prompt = '''
Generate $count technical interview questions for a "$position" position at "$company".
Respond with ONLY a JSON array of strings, no extra text:
["question1", "question2", "question3", "question4", "question5"]
''';

    final response = await http.post(
      Uri.parse(_generateUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.8,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode != 200) return [];

    try {
      final data = json.decode(response.body);
      final content =
          data['candidates'][0]['content']['parts'][0]['text'] as String;

      String cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final listStart = cleaned.indexOf('[');
      final listEnd = cleaned.lastIndexOf(']');
      if (listStart != -1 && listEnd != -1) {
        cleaned = cleaned.substring(listStart, listEnd + 1);
      }

      final List<dynamic> questions = json.decode(cleaned);
      return questions.map((q) => q.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // =====================
  // Validate API Key
  // =====================
  Future<bool> validateKey() async {
    try {
      final response = await http.post(
        Uri.parse(_generateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': 'Hi'}
              ]
            }
          ],
          'generationConfig': {'maxOutputTokens': 10},
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}