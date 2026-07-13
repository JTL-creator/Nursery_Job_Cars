import { useState } from 'react';
import { ChevronDown } from 'lucide-react';
import { StatusAtivo } from '../../types';
import { atualizarStatusAtivo } from '../../services/ativoService';
import { runAction } from '../../hooks/useApiData';
import { useI18n } from '../../hooks/useI18n';

const opcoes: { value: StatusAtivo; color: string }[] = [
  { value: 'DISPONIVEL', color: 'bg-green-100 text-green-800' },
  { value: 'MANUTENCAO', color: 'bg-orange-100 text-orange-800' },
  { value: 'INDISPONIVEL', color: 'bg-gray-100 text-gray-700' },
];

interface Props {
  ativoId: string;
  statusAtual: StatusAtivo;
  onChanged: () => void;
}

export default function StatusActionMenu({ ativoId, statusAtual, onChanged }: Props) {
  const { t } = useI18n();
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);

  const atual = opcoes.find((o) => o.value === statusAtual)
    || { value: statusAtual, color: 'bg-gray-100 text-gray-700' };

  const mudar = async (s: StatusAtivo) => {
    if (s === statusAtual) { setOpen(false); return; }
    setBusy(true);
    const r = await runAction(() => atualizarStatusAtivo(ativoId, s), t('ativ.toast.statusUpdated'));
    setBusy(false);
    setOpen(false);
    if (r) onChanged();
  };

  return (
    <div className="relative">
      <button
        onClick={() => setOpen((o) => !o)}
        disabled={busy || statusAtual === 'RESERVADO'}
        className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold ${atual.color} disabled:opacity-50`}
      >
        {t(`astatus.${statusAtual}`)}
        {statusAtual !== 'RESERVADO' && <ChevronDown size={12} />}
      </button>
      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
          <div className="absolute right-0 mt-1 z-20 bg-white dark:bg-gdm-blue2 rounded-lg shadow-lg border border-gray-200 dark:border-gdm-blue py-1 min-w-[140px]">
            {opcoes.map((o) => (
              <button
                key={o.value}
                onClick={() => mudar(o.value)}
                className="block w-full text-left px-3 py-1.5 text-xs hover:bg-gray-100 dark:hover:bg-gdm-blue"
              >
                {t(`astatus.${o.value}`)}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
