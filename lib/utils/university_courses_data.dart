/// Lista completa de cursos superiores no Brasil
class UniversityCoursesData {
  static final List<String> courses = [
    // Ciências Exatas e da Terra
    'Matemática',
    'Física',
    'Química',
    'Geologia',
    'Geografia',
    'Oceanografia',
    'Meteorologia',
    'Astronomia',
    'Estatística',
    
    // Ciências Biológicas
    'Biologia',
    'Biomedicina',
    'Biotecnologia',
    'Ciências Biológicas',
    'Ecologia',
    'Genética',
    
    // Engenharias
    'Engenharia Civil',
    'Engenharia Mecânica',
    'Engenharia Elétrica',
    'Engenharia de Produção',
    'Engenharia Química',
    'Engenharia de Computação',
    'Engenharia Ambiental',
    'Engenharia de Alimentos',
    'Engenharia Aeronáutica',
    'Engenharia Naval',
    'Engenharia de Materiais',
    'Engenharia de Petróleo',
    'Engenharia Florestal',
    'Engenharia Agrícola',
    'Engenharia de Minas',
    'Engenharia Cartográfica',
    'Engenharia de Controle e Automação',
    'Engenharia de Software',
    'Engenharia Biomédica',
    'Engenharia de Telecomunicações',
    
    // Ciências da Saúde
    'Medicina',
    'Enfermagem',
    'Odontologia',
    'Farmácia',
    'Fisioterapia',
    'Fonoaudiologia',
    'Terapia Ocupacional',
    'Nutrição',
    'Psicologia',
    'Medicina Veterinária',
    'Educação Física',
    'Radiologia',
    'Análises Clínicas',
    
    // Ciências Agrárias
    'Agronomia',
    'Zootecnia',
    'Engenharia de Pesca',
    'Recursos Pesqueiros',
    
    // Ciências Sociais Aplicadas
    'Direito',
    'Administração',
    'Ciências Contábeis',
    'Ciências Econômicas',
    'Arquitetura e Urbanismo',
    'Comunicação Social',
    'Jornalismo',
    'Publicidade e Propaganda',
    'Relações Públicas',
    'Turismo',
    'Hotelaria',
    'Serviço Social',
    'Ciências Políticas',
    'Relações Internacionais',
    'Gestão de Recursos Humanos',
    'Marketing',
    'Comércio Exterior',
    'Logística',
    'Gestão Financeira',
    'Processos Gerenciais',
    'Gestão Pública',
    
    // Ciências Humanas
    'Filosofia',
    'Sociologia',
    'Antropologia',
    'História',
    'Pedagogia',
    'Teologia',
    'Arqueologia',
    
    // Linguística, Letras e Artes
    'Letras',
    'Linguística',
    'Tradução',
    'Artes Visuais',
    'Música',
    'Teatro',
    'Dança',
    'Cinema',
    'Design',
    'Design Gráfico',
    'Design de Interiores',
    'Design de Moda',
    'Artes Plásticas',
    'Fotografia',
    
    // Tecnologia da Informação
    'Ciência da Computação',
    'Sistemas de Informação',
    'Análise e Desenvolvimento de Sistemas',
    'Tecnologia em Redes de Computadores',
    'Segurança da Informação',
    'Banco de Dados',
    'Gestão da Tecnologia da Informação',
    'Jogos Digitais',
    'Inteligência Artificial',
    
    // Educação
    'Licenciatura em Matemática',
    'Licenciatura em Física',
    'Licenciatura em Química',
    'Licenciatura em Biologia',
    'Licenciatura em História',
    'Licenciatura em Geografia',
    'Licenciatura em Letras',
    'Licenciatura em Educação Física',
    'Licenciatura em Artes',
    'Licenciatura em Música',
    'Educação Especial',
    
    // Outros Cursos Tecnológicos
    'Estética e Cosmética',
    'Gastronomia',
    'Eventos',
    'Recursos Humanos',
    'Secretariado',
    'Biblioteconomia',
    'Arquivologia',
    'Museologia',
    
    // Cursos Específicos
    'Atuária',
    'Meteorologia',
    'Geofísica',
    'Optometria',
    'Ortóptica',
    
    // Outros
    'Outro',
  ];

  /// Busca cursos que correspondem ao termo de busca
  static List<String> searchCourses(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    
    return courses.where((course) {
      return course.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Retorna todos os cursos
  static List<String> getAllCourses() {
    return List.from(courses);
  }

  /// Verifica se um nível de educação requer curso superior
  static bool requiresUniversityCourse(String? education) {
    if (education == null) return false;
    
    return [
      'ensino_superior',
      'pos_graduacao', 
      'mestrado',
      'doutorado'
    ].contains(education);
  }
}
