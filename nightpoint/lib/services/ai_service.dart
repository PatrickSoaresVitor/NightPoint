import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String apiKey = String.fromEnvironment('AI_API_KEY');

  String cleanAiText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('`', '')
        .trim();
  }

  Future<String> generateEventDescription({
    required String title,
    required String location,
    required String time,
    required String category,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key da IA não configurada.');
    }

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
- Não use markdown.
- Não use asteriscos.
- Não use negrito.
- Retorne apenas texto puro.
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
              {
                'text': prompt,
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao gerar descrição com IA.');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'];

    return cleanAiText(text);
  }

  Future<String> generateSharePost({
    required String title,
    required String location,
    required String time,
    required String category,
    required String description,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key da IA não configurada.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent',
    );

    final prompt = '''
Crie um post curto para divulgar um encontro automotivo.

Dados do evento:
Nome: $title
Local: $location
Horário: $time
Categoria: $category
Descrição: $description

Regras:
- Escreva em português do Brasil.
- Tom jovem, automotivo e organizado.
- Pode usar emojis moderadamente.
- Não incentive direção perigosa.
- Não mencione racha, corrida ilegal, burnout, drift em via pública ou manobras perigosas.
- Não use markdown.
- Não use asteriscos.
- Não use negrito.
- Retorne apenas o texto do post.
- Máximo 6 linhas.
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
              {
                'text': prompt,
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao gerar post com IA.');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'];

    return cleanAiText(text);
  }

  Future<String> analyzeEventSafety({
    required String title,
    required String location,
    required String time,
    required String category,
    required String description,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key da IA não configurada.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent',
    );

    final prompt = '''
Analise a segurança e adequação deste evento automotivo.

Dados do evento:
Nome: $title
Local: $location
Horário: $time
Categoria: $category
Descrição: $description

Critérios:
- Verifique se o texto incentiva direção perigosa.
- Verifique se menciona racha, corrida ilegal, burnout, drift em via pública, arrancada, manobras perigosas ou excesso de velocidade.
- Verifique se o evento parece organizado e seguro.
- Não seja exagerado: encontros automotivos comuns, exposição de carros, fotos, networking e socialização são permitidos.

Resposta obrigatória:
Status: Seguro, Atenção ou Inadequado
Análise: escreva uma explicação curta.
Sugestão: se necessário, sugira uma versão mais segura.

Regras:
- Escreva em português do Brasil.
- Não use markdown.
- Não use asteriscos.
- Não use negrito.
- Retorne apenas texto puro.
- Máximo 5 linhas.
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
              {
                'text': prompt,
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao analisar segurança com IA.');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'];

    return cleanAiText(text);
  }
  Future<Map<String, String>> generateCompleteEvent({
    required String idea,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key da IA não configurada.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent',
    );

    final prompt = '''
  Com base na ideia abaixo, crie dados para um encontro automotivo seguro e organizado.

  Ideia do usuário:
  $idea

  Retorne obrigatoriamente neste formato exato:

  TITULO: ...
  LOCAL: ...
  HORARIO: ...
  CATEGORIA: ...
  DESCRICAO: ...

  Categorias permitidas:
  Street, JDM, Premium, Drift

  Regras:
  - Não incentive direção perigosa.
  - Não mencione racha, corrida ilegal, burnout, drift em via pública ou manobras perigosas.
  - A categoria deve ser uma das categorias permitidas.
  - A descrição deve ter no máximo 2 frases.
  - Não use markdown.
  - Não use asteriscos.
  - Não use negrito.
  - Retorne apenas texto puro.
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
              {
                'text': prompt,
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao gerar evento com IA.');
    }

    final data = jsonDecode(response.body);
    final rawText = data['candidates'][0]['content']['parts'][0]['text'];
    final text = cleanAiText(rawText);

    String extractField(String field) {
      final regex = RegExp(
        '$field:\\s*(.*)',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);

      if (match == null) {
        return '';
      }

      return match.group(1)?.trim() ?? '';
    }

    final generatedCategory = extractField('CATEGORIA');

    final validCategories = [
      'Street',
      'JDM',
      'Premium',
      'Drift',
    ];

    final category = validCategories.contains(generatedCategory)
        ? generatedCategory
        : 'Street';

    return {
      'title': extractField('TITULO'),
      'location': extractField('LOCAL'),
      'time': extractField('HORARIO'),
      'category': category,
      'description': extractField('DESCRICAO'),
    };
  }
  Future<String> recommendEvents({
    required List<Map<String, dynamic>> events,
    Map<String, dynamic>? garage,
  }) async {

    if (events.isEmpty) {
      return 'Ainda não há eventos suficientes para recomendar.';
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent',
    );

    final garageText = garage == null
    ? 'Garagem não informada.'
    : garage.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');

    final eventsText = events.map((event) {
      return '''
  Evento:
  Título: ${event['title'] ?? 'Sem título'}
  Local: ${event['location'] ?? 'Local não informado'}
  Horário: ${event['time'] ?? 'Horário não informado'}
  Categoria: ${event['category'] ?? 'Evento'}
  Descrição: ${event['description'] ?? 'Sem descrição'}
  Participantes: ${(event['participants'] as List?)?.length ?? 0}
  Curtidas: ${(event['likes'] as List?)?.length ?? 0}
  ''';
    }).join('\n');

    final prompt = '''
  Você é uma IA assistente do app NightPoint, uma rede social de encontros automotivos.

  Perfil/Garagem do usuário:
  $garageText

  Analise os eventos abaixo e recomende até 3 eventos mais interessantes para o usuário.

  Eventos disponíveis:
  $eventsText

  Critérios:
  - Priorize eventos organizados, seguros e com boa proposta social.
  - Leve em conta a garagem do usuário para recomendar eventos compatíveis.
  - Se a garagem indicar carro premium, europeu, JDM, street ou drift, use isso como preferência.
  - Leve em conta categoria, descrição, movimentação, participantes e curtidas.
  - Não incentive direção perigosa.
  - Não mencione racha, corrida ilegal, burnout, drift em via pública ou manobras perigosas.

  Formato obrigatório:
  Recomendação 1: nome do evento
  Motivo: explicação curta

  Recomendação 2: nome do evento
  Motivo: explicação curta

  Recomendação 3: nome do evento
  Motivo: explicação curta

  Regras:
  - Escreva em português do Brasil.
  - Não use markdown.
  - Não use asteriscos.
  - Não use negrito.
  - Retorne apenas texto puro.
  - Seja direto.
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
              {
                'text': prompt,
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao recomendar eventos com IA.');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'];

    return cleanAiText(text);
  }
}