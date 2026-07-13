import { createContext, useEffect, useState, ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import * as authService from '../services/authService';
import { Usuario, PerfilNome } from '../types';
import toast from 'react-hot-toast';

interface AuthCtx {
  user: Usuario | null;
  perfil: PerfilNome | null;
  isAuthenticated: boolean;
  loading: boolean;
  login: (email: string, senha: string) => Promise<void>;
  logout: () => Promise<void>;
}

export const AuthContext = createContext<AuthCtx>({} as AuthCtx);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<Usuario | null>(null);
  const [perfil, setPerfil] = useState<PerfilNome | null>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    const cached = localStorage.getItem('usuario');
    if (token && cached) {
      try {
        const u = JSON.parse(cached) as Usuario;
        setUser(u);
        setPerfil((u.perfil as PerfilNome) || null);
      } catch { /* ignore */ }
      authService.me()
        .then((u) => {
          if (u) {
            setUser(u);
            setPerfil((u.perfil as PerfilNome) || null);
            localStorage.setItem('usuario', JSON.stringify(u));
          }
        })
        .catch(() => { /* interceptor cuida */ })
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, []);

  const login = async (email: string, senha: string) => {
    const data = await authService.login(email, senha);
    localStorage.setItem('access_token', data.access_token);
    localStorage.setItem('refresh_token', data.refresh_token);
    const usuarioCompleto: Usuario = { ...data.usuario, perfil: data.perfil };
    localStorage.setItem('usuario', JSON.stringify(usuarioCompleto));
    setUser(usuarioCompleto);
    setPerfil(data.perfil);
    toast.success(`Bem-vindo, ${data.usuario.nome_completo.split(' ')[0]}!`);
    navigate('/home');
  };

  const logout = async () => {
    await authService.logout();
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('usuario');
    setUser(null);
    setPerfil(null);
    navigate('/login');
  };

  return (
    <AuthContext.Provider
      value={{
        user, perfil, loading,
        isAuthenticated: !!user,
        login, logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
