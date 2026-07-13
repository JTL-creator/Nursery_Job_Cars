import api from './api';
import { ApiResponse, LoginResponse, Usuario } from '../types';

export async function login(email: string, senha: string) {
  const { data } = await api.post<ApiResponse<LoginResponse>>('/auth/login', {
    email, senha,
  });
  return data.data;
}

export async function logout() {
  try { await api.post('/auth/logout'); } catch { /* ignore */ }
}

export async function me() {
  const { data } = await api.get<ApiResponse<Usuario>>('/usuarios/me');
  return data.data;
}
