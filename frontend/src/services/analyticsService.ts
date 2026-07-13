import api from './api';
import { AnalyticsResumo, ApiResponse, UsoPorAtivo } from '../types';

export async function obterResumo() {
  const { data } = await api.get<ApiResponse<AnalyticsResumo>>('/analytics/resumo');
  return data.data;
}

export async function obterUsoPorAtivo() {
  const { data } = await api.get<ApiResponse<UsoPorAtivo[]>>('/analytics/uso-por-ativo');
  return data.data;
}

export async function obterOcorrencias() {
  const { data } = await api.get<ApiResponse<unknown[]>>('/analytics/ocorrencias');
  return data.data;
}
