import 'package:flutter/material.dart';

/// Componente para destacar termos de busca em texto
/// 
/// Destaca visualmente os termos encontrados nos resultados de busca
class HighlightedCertificationText extends StatelessWidget {
  final String text;
  final String? searchTerm;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const HighlightedCertificationText({
    Key? key,
    required this.text,
    this.searchTerm,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Se não há termo de busca, retorna texto normal
    if (searchTerm == null || searchTerm!.trim().isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    
    final defaultStyle = style ?? TextStyle();
    final defaultHighlightStyle = highlightStyle ?? TextStyle(
      backgroundColor: Colors.yellow.shade200,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    
    // Criar spans com destaque
    final spans = _buildHighlightedSpans(
      text,
      searchTerm!,
      defaultStyle,
      defaultHighlightStyle,
    );
    
    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
  
  /// Constrói spans com destaque para os termos encontrados
  List<TextSpan> _buildHighlightedSpans(
    String text,
    String searchTerm,
    TextStyle normalStyle,
    TextStyle highlightStyle,
  ) {
    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerSearch = searchTerm.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerSearch);
    
    while (index != -1) {
      // Adicionar texto antes do match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: normalStyle,
        ));
      }
      
      // Adicionar texto destacado
      spans.add(TextSpan(
        text: text.substring(index, index + searchTerm.length),
        style: highlightStyle,
      ));
      
      start = index + searchTerm.length;
      index = lowerText.indexOf(lowerSearch, start);
    }
    
    // Adicionar texto restante
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: normalStyle,
      ));
    }
    
    return spans;
  }
}

/// Widget helper para criar texto destacado de forma mais simples
class CertificationHighlight extends StatelessWidget {
  final String text;
  final String? searchTerm;
  final Color? highlightColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  
  const CertificationHighlight({
    Key? key,
    required this.text,
    this.searchTerm,
    this.highlightColor,
    this.fontSize,
    this.fontWeight,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return HighlightedCertificationText(
      text: text,
      searchTerm: searchTerm,
      style: TextStyle(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.normal,
      ),
      highlightStyle: TextStyle(
        backgroundColor: highlightColor ?? Colors.yellow.shade200,
        fontWeight: FontWeight.bold,
        fontSize: fontSize ?? 14,
        color: Colors.black87,
      ),
    );
  }
}
