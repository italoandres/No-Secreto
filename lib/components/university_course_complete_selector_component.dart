import 'package:flutter/material.dart';
import '../utils/university_courses_complete_data.dart';

/// Componente para seleção de curso universitário com busca
class UniversityCourseCompleteSelectorComponent extends StatefulWidget {
  final String? selectedCourse;
  final Function(String?) onCourseChanged;
  final Color primaryColor;
  final String hintText;

  const UniversityCourseCompleteSelectorComponent({
    super.key,
    this.selectedCourse,
    required this.onCourseChanged,
    required this.primaryColor,
    this.hintText = 'Digite para buscar seu curso',
  });

  @override
  State<UniversityCourseCompleteSelectorComponent> createState() =>
      _UniversityCourseCompleteSelectorComponentState();
}

class _UniversityCourseCompleteSelectorComponentState
    extends State<UniversityCourseCompleteSelectorComponent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredCourses = [];
  bool _showDropdown = false;
  String? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.selectedCourse;
    if (_selectedCourse != null) {
      _controller.text = _selectedCourse!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showDropdown = true;
      _updateFilteredCourses(_controller.text);
    } else {
      // Delay para permitir seleção do item
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _showDropdown = false;
          });
        }
      });
    }
    setState(() {});
  }

  void _updateFilteredCourses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCourses =
            UniversityCoursesCompleteData.getAllCourses().take(10).toList();
      } else {
        _filteredCourses = UniversityCoursesCompleteData.searchCourses(query)
            .take(10)
            .toList();
      }
    });
  }

  void _selectCourse(String course) {
    setState(() {
      _selectedCourse = course;
      _controller.text = course;
      _showDropdown = false;
    });
    _focusNode.unfocus();
    widget.onCourseChanged(course);
  }

  void _clearSelection() {
    setState(() {
      _selectedCourse = null;
      _controller.clear();
      _showDropdown = false;
    });
    widget.onCourseChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _focusNode.hasFocus ? widget.primaryColor : Colors.grey[300]!,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(
                Icons.school,
                color: _focusNode.hasFocus
                    ? widget.primaryColor
                    : Colors.grey[400],
              ),
              suffixIcon: _selectedCourse != null
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: _clearSelection,
                    )
                  : Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[400],
                    ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) {
              _updateFilteredCourses(value);
              setState(() {
                _showDropdown = value.isNotEmpty || _focusNode.hasFocus;
              });
            },
            onTap: () {
              setState(() {
                _showDropdown = true;
              });
              _updateFilteredCourses(_controller.text);
            },
          ),
        ),
        if (_showDropdown && _filteredCourses.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCourses.length,
              itemBuilder: (context, index) {
                final course = _filteredCourses[index];
                final isSelected = course == _selectedCourse;

                return InkWell(
                  onTap: () => _selectCourse(course),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.primaryColor.withOpacity(0.1)
                          : null,
                      border: index < _filteredCourses.length - 1
                          ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 18,
                          color: isSelected
                              ? widget.primaryColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            course,
                            style: TextStyle(
                              color: isSelected
                                  ? widget.primaryColor
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 18,
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
        if (_controller.text.isNotEmpty &&
            _filteredCourses.isEmpty &&
            _showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nenhum curso encontrado. Continue digitando...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
