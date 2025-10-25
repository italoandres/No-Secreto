/// Lista completa de profissões em português
class OccupationsData {
  static final List<String> occupations = [
    // Tecnologia e TI
    'Desenvolvedor(a) de Software',
    'Engenheiro(a) de Software',
    'Analista de Sistemas',
    'Programador(a)',
    'Designer UX/UI',
    'Cientista de Dados',
    'Analista de Dados',
    'Administrador(a) de Redes',
    'Analista de Segurança da Informação',
    'DevOps',
    'Arquiteto(a) de Software',
    'Gerente de TI',
    'Suporte Técnico',
    'Analista de Suporte',

    // Saúde
    'Médico(a)',
    'Enfermeiro(a)',
    'Dentista',
    'Farmacêutico(a)',
    'Fisioterapeuta',
    'Nutricionista',
    'Psicólogo(a)',
    'Terapeuta Ocupacional',
    'Fonoaudiólogo(a)',
    'Veterinário(a)',
    'Biomédico(a)',
    'Técnico(a) de Enfermagem',
    'Radiologista',
    'Cirurgião(ã)',

    // Educação
    'Professor(a)',
    'Pedagogo(a)',
    'Coordenador(a) Pedagógico(a)',
    'Diretor(a) de Escola',
    'Instrutor(a)',
    'Tutor(a)',
    'Professor(a) Universitário(a)',

    // Engenharia
    'Engenheiro(a) Civil',
    'Engenheiro(a) Mecânico(a)',
    'Engenheiro(a) Elétrico(a)',
    'Engenheiro(a) de Produção',
    'Engenheiro(a) Químico(a)',
    'Engenheiro(a) Ambiental',
    'Arquiteto(a)',
    'Engenheiro(a) de Segurança do Trabalho',

    // Direito e Jurídico
    'Advogado(a)',
    'Juiz(a)',
    'Promotor(a)',
    'Defensor(a) Público(a)',
    'Delegado(a)',
    'Escrivão(ã)',
    'Oficial de Justiça',

    // Administração e Negócios
    'Administrador(a)',
    'Gerente',
    'Diretor(a)',
    'Analista Administrativo(a)',
    'Assistente Administrativo(a)',
    'Secretário(a)',
    'Recepcionista',
    'Auxiliar Administrativo(a)',
    'Empresário(a)',
    'Empreendedor(a)',

    // Finanças e Contabilidade
    'Contador(a)',
    'Analista Financeiro(a)',
    'Auditor(a)',
    'Consultor(a) Financeiro(a)',
    'Economista',
    'Bancário(a)',
    'Gerente de Banco',
    'Caixa',

    // Marketing e Comunicação
    'Publicitário(a)',
    'Designer Gráfico(a)',
    'Jornalista',
    'Relações Públicas',
    'Analista de Marketing',
    'Social Media',
    'Copywriter',
    'Fotógrafo(a)',
    'Videomaker',
    'Editor(a) de Vídeo',

    // Vendas e Comércio
    'Vendedor(a)',
    'Representante Comercial',
    'Gerente de Vendas',
    'Consultor(a) de Vendas',
    'Promotor(a) de Vendas',
    'Comerciante',
    'Lojista',

    // Serviços
    'Cabeleireiro(a)',
    'Manicure',
    'Esteticista',
    'Maquiador(a)',
    'Personal Trainer',
    'Chef de Cozinha',
    'Cozinheiro(a)',
    'Garçom/Garçonete',
    'Barista',
    'Motorista',
    'Entregador(a)',
    'Segurança',
    'Porteiro(a)',
    'Zelador(a)',
    'Faxineiro(a)',
    'Jardineiro(a)',

    // Indústria e Produção
    'Operador(a) de Máquinas',
    'Técnico(a) Industrial',
    'Mecânico(a)',
    'Eletricista',
    'Soldador(a)',
    'Torneiro(a) Mecânico(a)',
    'Montador(a)',

    // Artes e Cultura
    'Artista',
    'Músico(a)',
    'Cantor(a)',
    'Ator/Atriz',
    'Dançarino(a)',
    'Escritor(a)',
    'Pintor(a)',
    'Escultor(a)',
    'Artesão(ã)',

    // Esportes
    'Atleta',
    'Treinador(a)',
    'Preparador(a) Físico(a)',
    'Árbitro(a)',

    // Religioso
    'Pastor(a)',
    'Padre',
    'Missionário(a)',
    'Líder de Ministério',
    'Diácono/Diaconisa',
    'Teólogo(a)',
    'Professor(a) de Teologia',
    'Capelão(ã)',
    'Evangelista',
    'Pregador(a)',

    // Outros
    'Autônomo(a)',
    'Freelancer',
    'Consultor(a)',
    'Aposentado(a)',
    'Estudante',
    'Desempregado(a)',
    'Do Lar',
    'Voluntário(a)',
    'Outro',
  ];

  /// Busca profissões que correspondem ao termo de busca
  static List<String> searchOccupations(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    return occupations.where((occupation) {
      return occupation.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Retorna todas as profissões
  static List<String> getAllOccupations() {
    return List.from(occupations);
  }
}
