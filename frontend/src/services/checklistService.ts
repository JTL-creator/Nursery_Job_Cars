import api from './api';
import {
  ApiResponse, Checklist, ChecklistTemplate, TipoAtivo, EtapaChecklist, NovoTemplate,
} from '../types';

export async function listarTemplates(filtros: {
  tipo_ativo?: TipoAtivo;
  etapa?: EtapaChecklist;
} = {}) {
  const { data } = await api.get<ApiResponse<ChecklistTemplate[]>>(
    '/checklists/templates', { params: filtros }
  );
  return data.data;
}

export async function obterTemplate(id: string) {
  const { data } = await api.get<ApiResponse<ChecklistTemplate>>(`/checklists/templates/${id}`);
  return data.data;
}

export async function criarTemplate(payload: NovoTemplate) {
  const { data } = await api.post<ApiResponse<ChecklistTemplate>>('/checklists/templates', payload);
  return data.data;
}

export async function atualizarTemplate(id: string, payload: Partial<NovoTemplate>) {
  const { data } = await api.patch<ApiResponse<ChecklistTemplate>>(`/checklists/templates/${id}`, payload);
  return data.data;
}

export async function excluirTemplate(id: string) {
  const { data } = await api.delete<ApiResponse<null>>(`/checklists/templates/${id}`);
  return data;
}

export async function obterChecklist(id: string) {
  const { data } = await api.get<ApiResponse<Checklist>>(`/checklists/${id}`);
  return data.data;
}
