/// Lista completa de cursos universitários no Brasil
class UniversityCoursesCompleteData {
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
    'Ciência da Computação',
    'Sistemas de Informação',
    'Engenharia de Software',
    'Análise e Desenvolvimento de Sistemas',

    // Ciências Biológicas
    'Biologia',
    'Ciências Biológicas',
    'Biotecnologia',
    'Biomedicina',
    'Biofísica',
    'Bioquímica',
    'Ecologia',
    'Genética',
    'Microbiologia',
    'Zoologia',
    'Botânica',

    // Engenharias
    'Engenharia Civil',
    'Engenharia Mecânica',
    'Engenharia Elétrica',
    'Engenharia Eletrônica',
    'Engenharia de Produção',
    'Engenharia Química',
    'Engenharia de Alimentos',
    'Engenharia Ambiental',
    'Engenharia Florestal',
    'Engenharia Agrícola',
    'Engenharia de Materiais',
    'Engenharia Naval',
    'Engenharia Aeronáutica',
    'Engenharia de Petróleo',
    'Engenharia de Minas',
    'Engenharia Cartográfica',
    'Engenharia de Controle e Automação',
    'Engenharia Biomédica',
    'Engenharia de Telecomunicações',
    'Engenharia da Computação',

    // Ciências da Saúde
    'Medicina',
    'Enfermagem',
    'Farmácia',
    'Odontologia',
    'Veterinária',
    'Fisioterapia',
    'Fonoaudiologia',
    'Terapia Ocupacional',
    'Nutrição',
    'Psicologia',
    'Educação Física',
    'Medicina Veterinária',
    'Radiologia',
    'Estética e Cosmética',
    'Optometria',

    // Ciências Agrárias
    'Agronomia',
    'Zootecnia',
    'Engenharia de Pesca',

    // Ciências Sociais Aplicadas
    'Direito',
    'Administração',
    'Economia',
    'Contabilidade',
    'Ciências Contábeis',
    'Arquitetura e Urbanismo',
    'Comunicação Social',
    'Jornalismo',
    'Publicidade e Propaganda',
    'Relações Públicas',
    'Rádio e TV',
    'Cinema',
    'Design',
    'Design Gráfico',
    'Design de Interiores',
    'Design de Moda',
    'Turismo',
    'Hotelaria',
    'Gastronomia',
    'Serviço Social',
    'Ciências Políticas',
    'Relações Internacionais',
    'Segurança Pública',
    'Biblioteconomia',
    'Arquivologia',
    'Museologia',

    // Ciências Humanas
    'História',
    'Filosofia',
    'Sociologia',
    'Antropologia',
    'Arqueologia',
    'Teologia',
    'Ciências da Religião',
    'Pedagogia',
    'Psicopedagogia',

    // Linguística, Letras e Artes
    'Letras',
    'Letras - Português',
    'Letras - Inglês',
    'Letras - Espanhol',
    'Letras - Francês',
    'Letras - Alemão',
    'Letras - Italiano',
    'Linguística',
    'Tradução',
    'Interpretação',
    'Música',
    'Artes Visuais',
    'Artes Plásticas',
    'Artes Cênicas',
    'Teatro',
    'Dança',
    'Cinema e Audiovisual',
    'Fotografia',
    'Design de Games',
    'Produção Musical',
    'Educação Artística',

    // Cursos Tecnológicos e Gestão
    'Gestão Ambiental',
    'Gestão Pública',
    'Gestão de Recursos Humanos',
    'Gestão Financeira',
    'Gestão Comercial',
    'Gestão da Qualidade',
    'Gestão de Agronegócios',
    'Gestão Hospitalar',
    'Gestão da Tecnologia da Informação',
    'Logística',
    'Marketing',
    'Comércio Exterior',
    'Processos Gerenciais',
    'Recursos Humanos',
    'Secretariado Executivo',
    'Eventos',
    'Segurança do Trabalho',
    'Meio Ambiente',
    'Saneamento Ambiental',
    'Construção Civil',
    'Eletrônica',
    'Eletrotécnica',
    'Mecânica',
    'Automação Industrial',
    'Telecomunicações',
    'Redes de Computadores',
    'Banco de Dados',
    'Jogos Digitais',
    'Internet das Coisas',
    'Inteligência Artificial',
    'Cibersegurança',
    'Big Data',
    'Ciência de Dados',
    'Data Science',
    'Robótica',
    'Mecatrônica',
    'Nanotecnologia',
    'Energias Renováveis',
    'Petróleo e Gás',
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

  /// Verifica se um curso existe na lista
  static bool isValidCourse(String courseName) {
    return courses.contains(courseName);
  }
}
