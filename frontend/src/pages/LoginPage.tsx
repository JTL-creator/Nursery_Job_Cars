import { FormEvent, useState } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { useI18n } from '../hooks/useI18n';
import Input from '../components/UI/Input';
import Button from '../components/UI/Button';
import toast from 'react-hot-toast';
import { LogIn } from 'lucide-react';

export default function LoginPage() {
  const { login, isAuthenticated } = useAuth();
  const { t, lang, setLang } = useI18n();
  const [email, setEmail] = useState('admin@gdm.com');
  const [senha, setSenha] = useState('');
  const [loading, setLoading] = useState(false);

  if (isAuthenticated) return <Navigate to="/home" replace />;

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!email || !senha) {
      toast.error(t('login.err.fill'));
      return;
    }
    try {
      setLoading(true);
      await login(email, senha);
    } catch {
      /* interceptor já mostra o erro */
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className="min-h-screen flex items-center justify-center p-4"
      style={{
        background: 'linear-gradient(135deg, #092A3B 0%, #0E3A52 60%, #B4BD00 180%)',
      }}
    >
      <div className="w-full max-w-md bg-white dark:bg-gdm-blue2 rounded-2xl shadow-xl p-8">
        <div className="flex justify-end mb-2">
          <div className="inline-flex rounded-full bg-gray-100 dark:bg-gdm-blue p-0.5">
            <button
              type="button"
              onClick={() => setLang('en')}
              className={`px-2.5 py-1 rounded-full text-[11px] font-semibold transition-colors ${lang === 'en' ? 'bg-gdm-lime text-gdm-blue' : 'text-gray-500'}`}
            >EN</button>
            <button
              type="button"
              onClick={() => setLang('pt')}
              className={`px-2.5 py-1 rounded-full text-[11px] font-semibold transition-colors ${lang === 'pt' ? 'bg-gdm-lime text-gdm-blue' : 'text-gray-500'}`}
            >PT</button>
          </div>
        </div>
        <div className="flex flex-col items-center mb-6">
          <img
            src="/favicon.svg"
            alt="GDM Job Cars"
            className="w-16 h-16 rounded-2xl shadow-lg"
          />
          <h1 className="text-xl font-bold mt-3 text-gdm-blue dark:text-white">
            GDM Job Cars
          </h1>
          <p className="text-xs text-gray-500 dark:text-gray-300">
            {t('login.subtitle')}
          </p>
        </div>

        <form onSubmit={onSubmit} className="flex flex-col gap-4">
          <Input
            label={t('login.email')}
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder={t('login.emailPlaceholder')}
            autoComplete="email"
          />
          <Input
            label={t('login.password')}
            type="password"
            value={senha}
            onChange={(e) => setSenha(e.target.value)}
            placeholder="••••••••"
            autoComplete="current-password"
          />

          <Button type="submit" loading={loading}>
            <LogIn size={16} /> {t('login.submit')}
          </Button>
        </form>

        <div className="mt-5 text-center text-sm">
          <Link
            to="/solicitar-cadastro"
            className="text-gdm-blue dark:text-gdm-lime font-medium hover:underline"
          >
            {t('login.request')}
          </Link>
        </div>

        <div className="mt-6 p-3 rounded-lg bg-gray-50 dark:bg-gdm-blue text-[11px] text-gray-600 dark:text-gray-300">
          <p className="font-semibold mb-1">{t('login.devCreds')}</p>
          <p>Email: <code>admin@gdm.com</code></p>
          <p>Senha: <code>Admin@123</code></p>
        </div>
      </div>
    </div>
  );
}
