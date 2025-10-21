import 'dart:math' as math;

/// Utilitário para matching de texto inteligente
class TextMatcher {
  /// Threshold mínimo para considerar uma similaridade válida
  static const double defaultSimilarityThreshold = 0.6;
  
  /// Peso para matching exato
  static const double exactMatchWeight = 1.0;
  
  /// Peso para matching de início de palavra
  static const double startOfWordWeight = 0.8;
  
  /// Peso para matching contido
  static const double containsWeight = 0.6;
  
  /// Peso para matching de similaridade
  static const double similarityWeight = 0.4;

  /// Verifica se um texto faz match com uma query
  static bool matches(String text, String query, {
    double threshold = defaultSimilarityThreshold,
    bool caseSensitive = false,
  }) {
    if (text.isEmpty || query.isEmpty) return false;
    
    final normalizedText = caseSensitive ? text : text.toLowerCase();
    final normalizedQuery = caseSensitive ? query : query.toLowerCase();
    
    // Match exato
    if (normalizedText == normalizedQuery) return true;
    
    // Match contido
    if (normalizedText.contains(normalizedQuery)) return true;
    
    // Match por similaridade
    final similarity = calculateSimilarity(normalizedText, normalizedQuery);
    return similarity >= threshold;
  }

  /// Calcula a similaridade entre dois textos (0.0 a 1.0)
  static double calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty && text2.isEmpty) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;
    if (text1 == text2) return 1.0;
    
    // Usar distância de Levenshtein normalizada
    final distance = _levenshteinDistance(text1, text2);
    final maxLength = math.max(text1.length, text2.length);
    
    return 1.0 - (distance / maxLength);
  }

  /// Calcula um score de matching mais sofisticado
  static double calculateMatchScore(String text, String query, {
    bool caseSensitive = false,
  }) {
    if (text.isEmpty || query.isEmpty) return 0.0;
    
    final normalizedText = caseSensitive ? text : text.toLowerCase();
    final normalizedQuery = caseSensitive ? query : query.toLowerCase();
    
    double score = 0.0;
    
    // Match exato - score máximo
    if (normalizedText == normalizedQuery) {
      return exactMatchWeight;
    }
    
    // Match de início de palavra
    final words = normalizedText.split(' ');
    for (final word in words) {
      if (word.startsWith(normalizedQuery)) {
        score = math.max(score, startOfWordWeight);
      }
    }
    
    // Match contido
    if (normalizedText.contains(normalizedQuery)) {
      score = math.max(score, containsWeight);
    }
    
    // Similaridade por distância de edição
    final similarity = calculateSimilarity(normalizedText, normalizedQuery);
    score = math.max(score, similarity * similarityWeight);
    
    return score;
  }

  /// Extrai keywords de um texto para indexação
  static List<String> extractKeywords(String text, {
    int minLength = 2,
    bool includePartials = true,
  }) {
    if (text.isEmpty) return [];
    
    final keywords = <String>{};
    
    // Normalizar texto removendo acentos
    final normalizedText = _normalizeText(text.toLowerCase());
    
    // Dividir por espaços e caracteres especiais
    final words = normalizedText
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length >= minLength)
        .toList();
    
    // Adicionar palavras completas
    keywords.addAll(words);
    
    // Adicionar prefixos se solicitado
    if (includePartials) {
      for (final word in words) {
        for (int i = minLength; i <= word.length; i++) {
          keywords.add(word.substring(0, i));
        }
      }
    }
    
    return keywords.toList();
  }
  
  /// Normaliza texto removendo acentos
  static String _normalizeText(String text) {
    return text
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  /// Busca fuzzy em uma lista de textos
  static List<MatchResult> fuzzySearch(
    List<String> texts,
    String query, {
    double threshold = defaultSimilarityThreshold,
    int maxResults = 50,
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) return [];
    
    final results = <MatchResult>[];
    
    for (int i = 0; i < texts.length; i++) {
      final text = texts[i];
      final score = calculateMatchScore(text, query, caseSensitive: caseSensitive);
      
      if (score >= threshold) {
        results.add(MatchResult(
          text: text,
          index: i,
          score: score,
          query: query,
        ));
      }
    }
    
    // Ordenar por score decrescente
    results.sort((a, b) => b.score.compareTo(a.score));
    
    // Limitar resultados
    return results.take(maxResults).toList();
  }

  /// Destaca os termos de busca em um texto
  static String highlightMatches(
    String text,
    String query, {
    String startTag = '<mark>',
    String endTag = '</mark>',
    bool caseSensitive = false,
  }) {
    if (text.isEmpty || query.isEmpty) return text;
    
    final normalizedQuery = caseSensitive ? query : query.toLowerCase();
    final searchText = caseSensitive ? text : text.toLowerCase();
    
    // Encontrar todas as ocorrências
    final matches = <Match>[];
    int start = 0;
    
    while (true) {
      final index = searchText.indexOf(normalizedQuery, start);
      if (index == -1) break;
      
      matches.add(Match(index, index + normalizedQuery.length));
      start = index + 1;
    }
    
    if (matches.isEmpty) return text;
    
    // Construir texto com destaques
    final buffer = StringBuffer();
    int lastEnd = 0;
    
    for (final match in matches) {
      // Adicionar texto antes do match
      buffer.write(text.substring(lastEnd, match.start));
      
      // Adicionar match destacado
      buffer.write(startTag);
      buffer.write(text.substring(match.start, match.end));
      buffer.write(endTag);
      
      lastEnd = match.end;
    }
    
    // Adicionar texto restante
    buffer.write(text.substring(lastEnd));
    
    return buffer.toString();
  }

  /// Sugere correções para uma query baseada em textos disponíveis
  static List<String> suggestCorrections(
    String query,
    List<String> availableTexts, {
    int maxSuggestions = 5,
    double threshold = 0.5,
  }) {
    if (query.isEmpty || availableTexts.isEmpty) return [];
    
    final suggestions = <SuggestionResult>[];
    final normalizedQuery = _normalizeText(query.toLowerCase());
    
    for (final text in availableTexts) {
      final normalizedText = _normalizeText(text.toLowerCase());
      final words = normalizedText.split(' ');
      
      for (final word in words) {
        if (word.length < 2) continue;
        
        final similarity = calculateSimilarity(normalizedQuery, word);
        if (similarity >= threshold) {
          suggestions.add(SuggestionResult(
            suggestion: word,
            similarity: similarity,
          ));
        }
      }
    }
    
    // Remover duplicatas e ordenar
    final uniqueSuggestions = <String, double>{};
    for (final suggestion in suggestions) {
      final current = uniqueSuggestions[suggestion.suggestion] ?? 0.0;
      uniqueSuggestions[suggestion.suggestion] = math.max(current, suggestion.similarity);
    }
    
    final sortedSuggestions = uniqueSuggestions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedSuggestions
        .take(maxSuggestions)
        .map((e) => e.key)
        .toList();
  }

  /// Calcula a distância de Levenshtein entre duas strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );
    
    // Inicializar primeira linha e coluna
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    // Preencher matriz
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        
        matrix[i][j] = math.min(
          math.min(
            matrix[i - 1][j] + 1,     // Deleção
            matrix[i][j - 1] + 1,     // Inserção
          ),
          matrix[i - 1][j - 1] + cost, // Substituição
        );
      }
    }
    
    return matrix[s1.length][s2.length];
  }
}

/// Resultado de um match de texto
class MatchResult {
  final String text;
  final int index;
  final double score;
  final String query;

  const MatchResult({
    required this.text,
    required this.index,
    required this.score,
    required this.query,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MatchResult &&
           other.text == text &&
           other.index == index &&
           other.score == score &&
           other.query == query;
  }

  @override
  int get hashCode {
    return Object.hash(text, index, score, query);
  }

  @override
  String toString() {
    return 'MatchResult(text: $text, index: $index, score: $score, query: $query)';
  }
}

/// Resultado de uma sugestão
class SuggestionResult {
  final String suggestion;
  final double similarity;

  const SuggestionResult({
    required this.suggestion,
    required this.similarity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SuggestionResult &&
           other.suggestion == suggestion &&
           other.similarity == similarity;
  }

  @override
  int get hashCode {
    return Object.hash(suggestion, similarity);
  }

  @override
  String toString() {
    return 'SuggestionResult(suggestion: $suggestion, similarity: $similarity)';
  }
}

/// Representa um match em um texto
class Match {
  final int start;
  final int end;

  const Match(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Match &&
           other.start == start &&
           other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(start, end);
  }

  @override
  String toString() {
    return 'Match(start: $start, end: $end)';
  }
}