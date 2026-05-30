import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String apiKey = String.fromEnvironment('AI_API_KEY');

  Future<String> generateEventDescription({
    required String title,
    required String location,
    required String time,
    required String category,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent',
    );

    final prompt = '''
Crie uma descrição curta, chamativa e profissional para um encontro automotivo.

Nome: $title
Local: $location
Horário: $time
Categoria: $category

Regras:
- Não incentive direção perigosa.
- Não mencione racha, corrida ilegal ou manobras perigosas.
- Tom jovem, automotivo e seguro.
- Máximo 2 frases.
''';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao gerar descrição com IA.');
    }

    final data = jsonDecode(response.body);

    return data['candidates'][0]['content']['parts'][0]['text'];
  }
}