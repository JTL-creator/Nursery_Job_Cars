import axios, { AxiosError } from 'axios';
import toast from 'react-hot-toast';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:5000/api/v1',
  timeout: 15000,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

let isRefreshing = false;

api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError<any>) => {
    const original: any = error.config;
    const status = error.response?.status;
    const code = error.response?.data?.error_code;

    if (status === 401 && code === 'AUTH_003' && !original?._retry) {
      original._retry = true;
      const refresh = localStorage.getItem('refresh_token');
      if (refresh && !isRefreshing) {
        try {
          isRefreshing = true;
          const r = await axios.post(
            `${api.defaults.baseURL}/auth/refresh`,
            { refresh_token: refresh }
          );
          const newToken = r.data?.data?.access_token;
          if (newToken) {
            localStorage.setItem('access_token', newToken);
            original.headers.Authorization = `Bearer ${newToken}`;
            isRefreshing = false;
            return api(original);
          }
        } catch {
          isRefreshing = false;
        }
      }
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      localStorage.removeItem('usuario');
      window.location.href = '/login';
      return Promise.reject(error);
    }

    const msg =
      error.response?.data?.message ||
      error.message ||
      'Erro inesperado na requisição';
    if (status && status >= 400) toast.error(msg);

    return Promise.reject(error);
  }
);

/** Resolve a URL completa de um arquivo enviado (ex.: /uploads/ativos/x.jpg). */
export function mediaUrl(path?: string | null): string {
  if (!path) return '';
  if (/^https?:\/\//.test(path)) return path;
  const base = api.defaults.baseURL || '';
  const origin = base.replace(/\/api\/v1\/?$/, '');
  return `${origin}${path.startsWith('/') ? '' : '/'}${path}`;
}

export default api;
