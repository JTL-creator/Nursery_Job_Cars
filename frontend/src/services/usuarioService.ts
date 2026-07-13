import api from './api';
import { ApiResponse, NovoUsuario, Perfil, StatusUsuario, Usuario } from '../types';

export interface FiltrosUsuarios {
    perfil?: string;
    status?: string;
    q?: string;
}

export async function listarUsuarios(filtros: FiltrosUsuarios = {}) {
    const { data } = await api.get<ApiResponse<Usuario[]>>('/usuarios', { params: filtros });
    return data;
}

export async function listarResponsaveis() {
    return listarUsuarios({ perfil: 'RESPONSAVEL' });
}

export async function listarPerfis() {
    const { data } = await api.get<ApiResponse<Perfil[]>>('/usuarios/perfis');
    return data.data;
}

export async function criarUsuario(payload: NovoUsuario) {
    const { data } = await api.post<ApiResponse<Usuario>>('/usuarios', payload);
    return data.data;
}

export async function atualizarUsuario(id: string, payload: Partial<NovoUsuario>) {
    const { data } = await api.patch<ApiResponse<Usuario>>(`/usuarios/${id}`, payload);
    return data.data;
}

export async function alterarStatusUsuario(id: string, status: StatusUsuario) {
    const { data } = await api.patch<ApiResponse<Usuario>>(`/usuarios/${id}/status`, { status });
    return data.data;
}

export async function redefinirSenhaUsuario(id: string, senha?: string) {
    const { data } = await api.post<ApiResponse<null>>(`/usuarios/${id}/redefinir-senha`, { senha });
    return data;
}
