import api from './api';
import { ApiResponse, SolicitacaoCadastro, SolicitacaoStatus } from '../types';

export interface NovaSolicitacao {
  nome_completo: string;
  matricula: string;
  email: string;
  telefone?: string;
  unidade_lotacao?: string;
  justificativa?: string;
}

export async function criarSolicitacao(payload: NovaSolicitacao) {
  const { data } = await api.post<ApiResponse<SolicitacaoCadastro>>(
    '/cadastros/solicitacoes', payload
  );
  return data.data;
}

export async function listarSolicitacoes(status?: SolicitacaoStatus) {
  const params = status ? { status } : {};
  const { data } = await api.get<ApiResponse<SolicitacaoCadastro[]>>(
    '/cadastros/solicitacoes', { params }
  );
  return data.data;
}

export async function aprovarSolicitacao(id: string) {
  const { data } = await api.patch<ApiResponse<unknown>>(
    `/cadastros/solicitacoes/${id}/aprovar`
  );
  return data;
}

export async function rejeitarSolicitacao(id: string, observacao_rejeicao: string) {
  const { data } = await api.patch<ApiResponse<unknown>>(
    `/cadastros/solicitacoes/${id}/rejeitar`,
    { observacao_rejeicao }
  );
  return data;
}
