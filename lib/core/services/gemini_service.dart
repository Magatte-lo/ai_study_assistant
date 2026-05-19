import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ai_service.dart';

/// Implémentation Gemini de [AIService].
///
/// Utilise l'API Google Gemini (gratuite jusqu'à 15 req/min).
/// Docs: https://ai.google.dev/gemini-api/docs
class GeminiService implements AIService {
  final Dio _dio;
  final String _apiKey;
  final String _model;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  GeminiService({
    Dio? dio,
    String? apiKey,
    String model = 'gemini-2.5-flash',
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '',
        _model = model {
    if (_apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY manquante. Vérifie ton fichier .env.',
      );
    }
  }

  @override
  Future<String> generateText(String prompt) async {
    final response = await _post(
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        }
      ],
    );
    return _extractText(response);
  }

  @override
  Future<String> generateChat({
    required List<AIMessage> messages,
    String? systemPrompt,
  }) async {
    final contents = messages.map((msg) {
      return {
        'role': msg.role == AIRole.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content}
        ],
      };
    }).toList();

    final response = await _post(
      contents: contents,
      systemInstruction: systemPrompt,
    );
    return _extractText(response);
  }

  @override
  Future<Map<String, dynamic>> generateJson({
    required String prompt,
    String? systemPrompt,
  }) async {
    final response = await _post(
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        }
      ],
      systemInstruction: systemPrompt,
      responseMimeType: 'application/json',
    );
    final text = _extractText(response);

    try {
      var cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?'), '').trim();
        cleaned = cleaned.replaceAll(RegExp(r'```$'), '').trim();
      }
      return Map<String, dynamic>.from(jsonDecode(cleaned));
    } catch (e) {
      throw Exception('Réponse JSON invalide de Gemini : $text');
    }
  }

  Future<Map<String, dynamic>> _post({
    required List<Map<String, dynamic>> contents,
    String? systemInstruction,
    String? responseMimeType,
  }) async {
    final url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';

    final body = <String, dynamic>{
      'contents': contents,
    };

    if (systemInstruction != null && systemInstruction.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction}
        ]
      };
    }

    if (responseMimeType != null) {
      body['generationConfig'] = {
        'responseMimeType': responseMimeType,
      };
    }

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        'Erreur Gemini API: ${e.response?.statusCode} - ${e.response?.data ?? e.message}',
      );
    }
  }

  String _extractText(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List;
      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      return parts[0]['text'] as String;
    } catch (e) {
      throw Exception('Format de réponse Gemini inattendu : $response');
    }
  }
}