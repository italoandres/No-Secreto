import 'package:flutter/material.dart';
import '../utils/university_courses_data.dart';

/// Componente para seleção de curso superior com autocomplete
class UniversityCourseSelectorComponent extends StatefulWidget {
  final String? selectedCourse;
  final String? selectedUniversity;
  final Function(String?) onCourseChanged;
  final Function(String?) onUniversityChanged;
  final Color primaryColor;

  const UniversityCourseSelectorComponent({
    super.key,
    this.selectedCourse,
    this.selectedUniversity,
    required this.onCourseChanged,
    required this.onUniversityChanged,
    required this.primaryColor,
  });

  @override
  State<UniversityCourseSelectorComponent> createState() =>
      _UniversityCourseSelectorComponentState();
}

class _UniversityCourseSelectorComponentState
    extends State<UniversityCourseSelectorComponent> {
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final FocusNode _courseFocusNode = FocusNode();
  final FocusNode _universityFocusNode = FocusNode();

  List<String> _courseSuggestions = [];
  bool _showCourseSuggestions = false;
  String? _selectedCourse;
  String? _selectedUniversity;

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.selectedCourse;
    _selectedUniversity = widget.selectedUniversity;

    if (_selectedCourse != null) {
      _courseController.text = _selectedCourse!;
    }
    if (_selectedUniversity != null) {
      _universityController.text = _selectedUniversity!;
    }

    _courseFocusNode.addListener(() {
      if (!_courseFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showCourseSuggestions = false;
            });
          }
        });
      }
    });
  }

  void _onCourseSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _courseSuggestions = [];
        _showCourseSuggestions = false;
      } else {
        _courseSuggestions = UniversityCoursesData.searchCourses(query);
        _showCourseSuggestions = _courseSuggestions.isNotEmpty;
      }
    });
  }

  void _selectCourse(String course) {
    setState(() {
      _selectedCourse = course;
      _courseController.text = course;
      _showCourseSuggestions = false;
      _courseSuggestions = [];
    });
    _courseFocusNode.unfocus();
    widget.onCourseChanged(course);
  }

  void _clearCourse() {
    setState(() {
      _selectedCourse = null;
      _courseController.clear();
      _courseSuggestions = [];
      _showCourseSuggestions = false;
    });
    widget.onCourseChanged(null);
  }

  void _onUniversityChanged(String value) {
    setState(() {
      _selectedUniversity = value.trim();
    });
    widget.onUniversityChanged(value.trim().isEmpty ? null : value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de curso
        TextFormField(
          controller: _courseController,
          focusNode: _courseFocusNode,
          decoration: InputDecoration(
            labelText: 'Curso Superior *',
            hintText: 'Digite para buscar...',
            prefixIcon: Icon(Icons.school, color: widget.primaryColor),
            suffixIcon: _courseController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearCourse,
                  )
                : Icon(Icons.search, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.primaryColor, width: 2),
            ),
            helperText: 'Ex: Engenharia, Medicina, Direito...',
            helperStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          onChanged: _onCourseSearchChanged,
          onTap: () {
            if (_courseController.text.isNotEmpty) {
              _onCourseSearchChanged(_courseController.text);
            }
          },
          validator: (value) {
            if (value?.trim().isEmpty == true) {
              return 'Por favor, informe seu curso';
            }
            return null;
          },
        ),

        // Lista de sugestões de cursos
        if (_showCourseSuggestions && _courseSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: widget.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_courseSuggestions.length} curso${_courseSuggestions.length != 1 ? 's' : ''} encontrado${_courseSuggestions.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de cursos
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _courseSuggestions.length,
                    itemBuilder: (context, index) {
                      final course = _courseSuggestions[index];
                      final isSelected = _selectedCourse == course;

                      return InkWell(
                        onTap: () => _selectCourse(course),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.primaryColor.withOpacity(0.1)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 20,
                                color: isSelected
                                    ? widget.primaryColor
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  course,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? widget.primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: widget.primaryColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        // Mensagem quando não há resultados
        if (_showCourseSuggestions &&
            _courseSuggestions.isEmpty &&
            _courseController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curso não encontrado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Você pode digitar manualmente o nome do seu curso',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Campo de universidade/faculdade
        TextFormField(
          controller: _universityController,
          focusNode: _universityFocusNode,
          decoration: InputDecoration(
            labelText: 'Instituição de Ensino',
            hintText: 'Ex: USP, UNICAMP, PUC...',
            prefixIcon: Icon(Icons.account_balance, color: widget.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.primaryColor, width: 2),
            ),
            helperText: 'Nome da universidade ou faculdade (opcional)',
            helperStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          onChanged: _onUniversityChanged,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _courseController.dispose();
    _universityController.dispose();
    _courseFocusNode.dispose();
    _universityFocusNode.dispose();
    super.dispose();
  }
}
