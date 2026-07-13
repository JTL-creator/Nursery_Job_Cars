export type PerfilNome = 'USUARIO' | 'ADMINISTRADOR' | 'GERENTE' | 'RESPONSAVEL';
export type StatusUsuario = 'ATIVO' | 'INATIVO' | 'BLOQUEADO';

export interface Usuario {
  id: string;
  nome_completo: string;
  matricula?: string;
  email: string;
  telefone?: string;
  unidade_lotacao?: string;
  status?: string;
  ultimo_login_em?: string;
  perfil?: PerfilNome;
}

export interface NovoUsuario {
  nome_completo: string;
  matricula: string;
  email: string;
  telefone?: string;
  unidade_lotacao?: string;
  perfil: PerfilNome;
  senha?: string;
}

export interface Perfil {
  id: number;
  nome: PerfilNome;
  descricao?: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  expires_in: string;
  usuario: Usuario;
  perfil: PerfilNome;
}

export interface ApiResponse<T> {
  data: T;
  message?: string;
  meta?: Record<string, unknown>;
}

export interface ApiError {
  error_code: string;
  message: string;
  details?: unknown;
  timestamp: string;
  trace_id: string;
}

// ===== Solicitações =====
export type SolicitacaoStatus = 'PENDENTE' | 'APROVADA' | 'REJEITADA';

export interface SolicitacaoCadastro {
  id: string;
  nome_completo: string;
  matricula: string;
  email: string;
  telefone?: string;
  unidade_lotacao?: string;
  justificativa?: string;
  status: SolicitacaoStatus;
  analisado_por?: string;
  analisado_em?: string;
  observacao_rejeicao?: string;
  criado_em: string;
  atualizado_em: string;
}

// ===== Ativos =====
export type TipoAtivo = 'VEICULO' | 'MAQUINA_AGRICOLA' | 'IMPLEMENTO';
export type StatusAtivo = 'DISPONIVEL' | 'RESERVADO' | 'INDISPONIVEL' | 'MANUTENCAO';

export interface Ativo {
  id: string;
  codigo_interno: string;
  descricao: string;
  tipo_ativo: TipoAtivo;
  sub_tipo?: string;
  placa?: string;
  patrimonio?: string;
  unidade?: string;
  status: StatusAtivo;
  observacoes?: string;
  responsavel_id?: string;
  responsavel_nome?: string;
  equipe?: string;
  foto_url?: string;
  criado_em?: string;
  atualizado_em?: string;
  disponivel?: boolean;
}

export interface NovoAtivo {
  codigo_interno: string;
  descricao: string;
  tipo_ativo: TipoAtivo;
  sub_tipo?: string;
  placa?: string;
  patrimonio?: string;
  unidade?: string;
  observacoes?: string;
  responsavel_id?: string | null;
  equipe?: string | null;
  foto_url?: string | null;
}

// ===== Reservas =====
export type StatusReserva =
  | 'PENDENTE' | 'CONFIRMADA' | 'EM_USO'
  | 'CONCLUIDA' | 'CANCELADA' | 'EXPIRADA' | 'REJEITADA';

export interface Reserva {
  id: string;
  usuario_id: string;
  ativo_id: string;
  data_hora_inicio: string;
  data_hora_fim: string;
  status: StatusReserva;
  motivo?: string;
  observacoes?: string;
  criado_em?: string;
  confirmado_em?: string;
  cancelado_em?: string;
  // joins
  codigo_interno?: string;
  ativo_descricao?: string;
  tipo_ativo?: TipoAtivo;
  placa?: string;
  usuario_nome?: string;
  usuario_email?: string;
}

// ===== Checklist =====
export type EtapaChecklist = 'RETIRADA' | 'DEVOLUCAO';

export interface ChecklistTemplateItem {
  id: string;
  template_id: string;
  chave_item: string;
  descricao: string;
  tipo_campo: 'texto' | 'numero' | 'booleano' | 'selecao' | 'data' | 'observacao';
  obrigatorio: boolean;
  ordem: number;
  opcoes_json?: { opcoes?: string[] } | null;
}

export interface ChecklistTemplate {
  id: string;
  tipo_ativo: TipoAtivo;
  etapa: EtapaChecklist;
  nome: string;
  ativo: boolean;
  versao: number;
  criado_em?: string;
  itens?: ChecklistTemplateItem[];
}

export type TipoCampo = 'texto' | 'numero' | 'booleano' | 'selecao' | 'data' | 'observacao';

export interface TemplateItemInput {
  chave_item?: string;
  descricao: string;
  tipo_campo: TipoCampo;
  obrigatorio: boolean;
  ordem?: number;
  opcoes?: string[];
}

export interface NovoTemplate {
  tipo_ativo: TipoAtivo;
  etapa: EtapaChecklist;
  nome: string;
  itens: TemplateItemInput[];
}

export interface Checklist {
  id: string;
  reserva_id: string;
  ativo_id: string;
  usuario_id: string;
  tipo_checklist: string;
  etapa: EtapaChecklist;
  data_hora_evento: string;
  local?: string;
  responsavel?: string;
  observacoes?: string;
  criado_em?: string;
  // joins
  codigo_interno?: string;
  ativo_descricao?: string;
  usuario_nome?: string;
  itens?: ChecklistItem[];
}

export interface ChecklistItem {
  id: string;
  checklist_id: string;
  chave_item: string;
  descricao_item?: string;
  valor_texto?: string;
  valor_numero?: number;
  valor_booleano?: boolean;
  obrigatorio: boolean;
  ordem: number;
}

// ===== Analytics =====
export interface AnalyticsResumo {
  ativos: {
    total: number;
    disponiveis: number;
    reservados: number;
    manutencao: number;
    indisponiveis: number;
  };
  reservas: {
    total: number;
    ativas: number;
    hoje: number;
  };
  checklists: {
    total: number;
    hoje: number;
  };
  usuarios: {
    total_ativos: number;
  };
}

export interface UsoPorAtivo {
  id: string;
  codigo_interno: string;
  descricao: string;
  tipo_ativo: TipoAtivo;
  total_reservas: number;
  concluidas: number;
}
