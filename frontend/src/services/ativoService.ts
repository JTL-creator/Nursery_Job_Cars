import api from './api';
import { ApiResponse, Ativo, NovoAtivo, StatusAtivo, TipoAtivo } from '../types';

export interface FiltrosAtivos {
  tipo_ativo?: TipoAtivo;
  status?: StatusAtivo;
  unidade?: string;
  equipe?: string;
  q?: string;
  limit?: number;
  offset?: number;
}

export async function listarAtivos(filtros: FiltrosAtivos = {}) {
  const { data } = await api.get<ApiResponse<Ativo[]>>('/ativos', { params: filtros });
  return data;
}

export async function obterAtivo(id: string) {
  const { data } = await api.get<ApiResponse<Ativo>>(`/ativos/${id}`);
  return data.data;
}

export async function criarAtivo(payload: NovoAtivo) {
  const { data } = await api.post<ApiResponse<Ativo>>('/ativos', payload);
  return data.data;
}

export async function atualizarAtivo(id: string, payload: Partial<NovoAtivo>) {
  const { data } = await api.patch<ApiResponse<Ativo>>(`/ativos/${id}`, payload);
  return data.data;
}

export async function atualizarStatusAtivo(id: string, status: StatusAtivo) {
  const { data } = await api.patch<ApiResponse<Ativo>>(`/ativos/${id}/status`, { status });
  return data.data;
}

export async function excluirAtivo(id: string) {
  const { data } = await api.delete<ApiResponse<null>>(`/ativos/${id}`);
  return data;
}

export async function uploadFotoAtivo(file: File) {
  const form = new FormData();
  form.append('foto', file);
  const { data } = await api.post<ApiResponse<{ url: string }>>('/ativos/foto', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return data.data.url;
}
