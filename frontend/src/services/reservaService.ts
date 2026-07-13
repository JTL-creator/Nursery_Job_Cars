import api from './api';
import { ApiResponse, Ativo, Reserva, StatusReserva } from '../types';

export interface FiltrosReservas {
  status?: StatusReserva;
  limit?: number;
  offset?: number;
}

export interface FiltrosDisponibilidade {
  inicio: string; // ISO
  fim: string; // ISO
  tipo_ativo?: string;
  unidade?: string;
}

export async function consultarDisponibilidade(filtros: FiltrosDisponibilidade) {
  const { data } = await api.get<ApiResponse<Ativo[]>>(
    '/reservas/disponibilidade',
    { params: filtros }
  );
  return data.data;
}

export async function criarReserva(payload: {
  ativo_id: string;
  data_hora_inicio: string;
  data_hora_fim: string;
  motivo?: string;
  observacoes?: string;
}) {
  const { data } = await api.post<ApiResponse<Reserva>>('/reservas', payload);
  return data.data;
}

export async function listarTodasReservas(filtros: FiltrosReservas = {}) {
  const { data } = await api.get<ApiResponse<Reserva[]>>('/reservas', { params: filtros });
  return data;
}

export async function obterReserva(id: string) {
  const { data } = await api.get<ApiResponse<Reserva>>(`/reservas/${id}`);
  return data.data;
}

export async function confirmarReserva(id: string) {
  const { data } = await api.patch<ApiResponse<Reserva>>(`/reservas/${id}/confirmar`);
  return data.data;
}

export async function iniciarReserva(id: string) {
  const { data } = await api.patch<ApiResponse<Reserva>>(`/reservas/${id}/iniciar-uso`);
  return data.data;
}

export async function concluirReserva(id: string) {
  const { data } = await api.patch<ApiResponse<Reserva>>(`/reservas/${id}/concluir`);
  return data.data;
}

export async function cancelarReserva(id: string) {
  const { data } = await api.patch<ApiResponse<Reserva>>(`/reservas/${id}/cancelar`);
  return data.data;
}
