import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const _apiKey = 'AIzaSyBffy-WWxudAdvmu_U_emm60tjvpRT5k4Y';
  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// Categorize a complaint and assign priority.
  /// Returns {category, priority, routeTo}
  static Future<Map<String, String>> categorizeComplaint(String title, String description) async {
    final prompt = '''You are a society/apartment complaint categorization system.
Given the complaint below, return a JSON object with exactly these keys:
- "category": one of [Plumbing, Electrical, Security, Parking, Noise, Cleanliness, Elevator, Other]
- "priority": one of [high, medium, low] based on urgency (safety/health=high, inconvenience=medium, minor=low)
- "routeTo": the relevant committee role (e.g. "Maintenance Head", "Security In-charge", "Parking Manager", "General Secretary")

Complaint Title: $title
Complaint Description: $description

Return ONLY valid JSON, no markdown.''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      // Extract JSON from response
      final jsonStr = text.contains('{') ? text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1) : '{}';
      final parsed = json.decode(jsonStr) as Map<String, dynamic>;
      return {
        'category': parsed['category']?.toString() ?? 'Other',
        'priority': parsed['priority']?.toString().toLowerCase() ?? 'medium',
        'routeTo': parsed['routeTo']?.toString() ?? 'General Secretary',
      };
    } catch (e) {
      return {'category': 'Other', 'priority': 'medium', 'routeTo': 'General Secretary'};
    }
  }

  /// Polish announcement text into a professional notice
  static Future<String> polishAnnouncement(String roughText) async {
    final prompt = '''You are a professional society notice writer for an Indian residential apartment complex.
Take this rough text and rewrite it as a clear, professional notice/announcement. Keep it concise but formal.
Do NOT add any subject line or title - just the body text.

Rough text: $roughText

Return ONLY the polished text, no markdown formatting.''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? roughText;
    } catch (e) {
      return roughText;
    }
  }

  /// Translate text to Hindi
  static Future<String> translateToHindi(String text) async {
    final prompt = '''Translate the following English text to Hindi (Devanagari script). Return ONLY the Hindi translation, nothing else.

Text: $text''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? text;
    } catch (e) {
      return text;
    }
  }
}
