import { FormEvent, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import Input from '../components/UI/Input';
import Button from '../components/UI/Button';
import { criarSolicitacao } from '../services/cadastroService';
import { useI18n } from '../hooks/useI18n';
import toast from 'react-hot-toast';
import { UserPlus, ArrowLeft } from 'lucide-react';

export default function SolicitarCadastroPage() {
  const navigate = useNavigate();
  const { t } = useI18n();
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    nome_completo: '',
    matricula: '',
    email: '',
    telefone: '',
    unidade_lotacao: '',
    justificativa: '',
  });

  const upd = (k: keyof typeof form) =>
    (e: React.ChangeEvent<HTMLInputElement>) =>
      setForm((s) => ({ ...s, [k]: e.target.value }));

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.nome_completo || !form.matricula || !form.email) {
      toast.error(t('reg.err.fill'));
      return;
    }
    try {
      setLoading(true);
      await criarSolicitacao(form);
      toast.success(t('reg.toast.sent'));
      setTimeout(() => navigate('/login'), 1500);
    } catch {
      /* interceptor cuida */
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
      <div className="w-full max-w-lg bg-white dark:bg-gdm-blue2 rounded-2xl shadow-xl p-6 md:p-8">
        <div className="flex items-center gap-2 mb-5">
          <UserPlus className="text-gdm-blue dark:text-gdm-lime" />
          <h1 className="text-lg font-bold text-gdm-blue dark:text-white">
            {t('reg.title')}
          </h1>
        </div>

        <form onSubmit={onSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Input label={t('reg.name')} value={form.nome_completo} onChange={upd('nome_completo')} />
          <Input label={t('reg.registration')} value={form.matricula} onChange={upd('matricula')} />
          <Input label={t('reg.email')} type="email" value={form.email} onChange={upd('email')} />
          <Input label={t('reg.phone')} value={form.telefone} onChange={upd('telefone')} />
          <Input
            label={t('reg.unit')}
            value={form.unidade_lotacao}
            onChange={upd('unidade_lotacao')}
            className="md:col-span-2"
          />
          <div className="md:col-span-2">
            <label className="text-sm font-medium text-gdm-blue dark:text-gray-200">
              {t('reg.justification')}
            </label>
            <textarea
              value={form.justificativa}
              onChange={(e) => setForm((s) => ({ ...s, justificativa: e.target.value }))}
              rows={3}
              className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 bg-white dark:bg-gdm-blue dark:text-white dark:border-gdm-blue
                         focus:outline-none focus:ring-2 focus:ring-gdm-lime"
              placeholder={t('reg.justificationPlaceholder')}
            />
          </div>

          <div className="md:col-span-2 flex flex-col-reverse md:flex-row justify-between gap-3 mt-2">
            <Link to="/login" className="text-sm text-gdm-blue dark:text-gdm-lime flex items-center gap-1 hover:underline">
              <ArrowLeft size={14} /> {t('reg.back')}
            </Link>
            <Button type="submit" loading={loading}>{t('reg.submit')}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
