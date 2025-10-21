import 'package:flutter/material.dart';

/// Componente para destacar termos de busca no texto
class HighlightedTextComponent extends StatelessWidget {
  final String text;
  final String? searchQuery;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const HighlightedTextComponent({
    Key? key,
    required this.text,
    this.searchQuery,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    return RichText(
      text: _buildHighlightedTextSpan(),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textAlign: textAlign ?? TextAlign.start,
    );
  }

  TextSpan _buildHighlightedTextSpan() {
    final defaultStyle = style ?? const TextStyle();
    final defaultHighlightStyle = highlightStyle ?? TextStyle(
      backgroundColor: Colors.yellow[200],
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    // Dividir a query em palavras individuais
    final queryWords = searchQuery!
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    if (queryWords.isEmpty) {
      return TextSpan(text: text, style: defaultStyle);
    }

    // Encontrar todas as ocorrências das palavras de busca
    final List<HighlightMatch> matches = [];
    final lowerText = text.toLowerCase();

    for (final word in queryWords) {
      int startIndex = 0;
      while (true) {
        final index = lowerText.indexOf(word, startIndex);
        if (index == -1) break;

        // Verificar se é uma palavra completa (não parte de outra palavra)
        final isWordBoundary = _isWordBoundary(lowerText, index, word.length);
        
        if (isWordBoundary) {
          matches.add(HighlightMatch(
            start: index,
            end: index + word.length,
            word: word,
          ));
        }
        
        startIndex = index + 1;
      }
    }

    // Ordenar matches por posição
    matches.sort((a, b) => a.start.compareTo(b.start));

    // Mesclar matches sobrepostos
    final mergedMatches = _mergeOverlappingMatches(matches);

    if (mergedMatches.isEmpty) {
      return TextSpan(text: text, style: defaultStyle);
    }

    // Construir TextSpan com destaques
    final List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final match in mergedMatches) {
      // Adicionar texto antes do match
      if (currentIndex < match.start) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: defaultStyle,
        ));
      }

      // Adicionar texto destacado
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: defaultStyle.merge(defaultHighlightStyle),
      ));

      currentIndex = match.end;
    }

    // Adicionar texto restante
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: defaultStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  /// Verifica se a posição representa uma palavra completa
  bool _isWordBoundary(String text, int start, int length) {
    // Verificar caractere anterior
    if (start > 0) {
      final prevChar = text[start - 1];
      if (RegExp(r'[a-zA-Z0-9À-ÿ]').hasMatch(prevChar)) {
        return false;
      }
    }

    // Verificar caractere posterior
    final end = start + length;
    if (end < text.length) {
      final nextChar = text[end];
      if (RegExp(r'[a-zA-Z0-9À-ÿ]').hasMatch(nextChar)) {
        return false;
      }
    }

    return true;
  }

  /// Mescla matches sobrepostos ou adjacentes
  List<HighlightMatch> _mergeOverlappingMatches(List<HighlightMatch> matches) {
    if (matches.isEmpty) return matches;

    final merged = <HighlightMatch>[];
    HighlightMatch current = matches.first;

    for (int i = 1; i < matches.length; i++) {
      final next = matches[i];
      
      // Se há sobreposição ou adjacência, mesclar
      if (current.end >= next.start - 1) {
        current = HighlightMatch(
          start: current.start,
          end: next.end > current.end ? next.end : current.end,
          word: '${current.word} ${next.word}',
        );
      } else {
        merged.add(current);
        current = next;
      }
    }

    merged.add(current);
    return merged;
  }
}

/// Representa uma correspondência de destaque no texto
class HighlightMatch {
  final int start;
  final int end;
  final String word;

  HighlightMatch({
    required this.start,
    required this.end,
    required this.word,
  });

  @override
  String toString() => 'HighlightMatch(start: $start, end: $end, word: $word)';
}

/// Widget helper para criar texto destacado rapidamente
class QuickHighlightText extends StatelessWidget {
  final String text;
  final String? searchQuery;
  final double? fontSize;
  final Color? textColor;
  final Color? highlightColor;
  final FontWeight? fontWeight;
  final int? maxLines;

  const QuickHighlightText({
    Key? key,
    required this.text,
    this.searchQuery,
    this.fontSize,
    this.textColor,
    this.highlightColor,
    this.fontWeight,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HighlightedTextComponent(
      text: text,
      searchQuery: searchQuery,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: fontSize ?? 14,
        color: textColor ?? Colors.black87,
        fontWeight: fontWeight ?? FontWeight.normal,
      ),
      highlightStyle: TextStyle(
        backgroundColor: highlightColor ?? Colors.yellow[200],
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

/// Widget para destacar texto em cards de perfil
class ProfileHighlightText extends StatelessWidget {
  final String text;
  final String? searchQuery;
  final bool isTitle;
  final int? maxLines;

  const ProfileHighlightText({
    Key? key,
    required this.text,
    this.searchQuery,
    this.isTitle = false,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HighlightedTextComponent(
      text: text,
      searchQuery: searchQuery,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: isTitle ? 16 : 14,
        fontWeight: isTitle ? FontWeight.w600 : FontWeight.normal,
        color: isTitle ? Colors.black87 : Colors.grey[700],
      ),
      highlightStyle: TextStyle(
        backgroundColor: Colors.blue[100],
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }
}