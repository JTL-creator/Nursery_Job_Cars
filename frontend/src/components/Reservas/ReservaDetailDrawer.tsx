import { useEffect, useState } from 'react';
import { X, Calendar, User, Car, MapPin, FileText, Clock, CheckCircle2, XCircle } from 'lucide-react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import Button from '../UI/Button';
import Spinner from '../UI/Spinner';
import ReservaStatusBadge from './ReservaStatusBadge';
import { Reserva } from '../../types';
import { obterReserva, cancelarReserva, confirmarReserva } from '../../services/reservaService';
import { runAction } from '../../hooks/useApiData';
import { useI18n } from '../../hooks/useI18n';

interface Props {
  reservaId: string | null;
  onClose: () => void;
  onChanged: () => void;
}

export default function ReservaDetailDrawer({ reservaId, onClose, onChanged }: Props) {
  const { t } = useI18n();
  const [r, setR] = useState<Reserva | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!reservaId) { setR(null); return; }
    (async () => {
      setLoading(true);
      try { setR(await obterReserva(reservaId)); }
      finally { setLoading(false); }
    })();
  }, [reservaId]);

  if (!reservaId) return null;

  const fmt = (iso?: string) =>
    iso ? format(new Date(iso), 'dd/MM/yyyy HH:mm', { locale: ptBR }) : '—';

  const horas = r ? Math.round(
    (new Date(r.data_hora_fim).getTime() - new Date(r.data_hora_inicio).getTime()) / 3600000
  ) : 0;

  const confirmarAdmin = async () => {
    if (!r) return;
    const ok = await runAction(() => confirmarReserva(r.id), t('drw.toast.confirmed'));
    if (ok) { onChanged(); setR(ok); }
  };

  const cancelarAdmin = async () => {
    if (!r) return;
    if (!confirm(t('drw.confirmCancel'))) return;
    const ok = await runAction(() => cancelarReserva(r.id), t('drw.toast.cancelled'));
    if (ok) { onChanged(); setR(ok); }
  };

  return (
    <div className="fixed inset-0 z-50 flex justify-end" onClick={onClose}>
      <div className="absolute inset-0 bg-black/50" />
      <div
        className="relative bg-white dark:bg-gdm-blue2 w-full max-w-md h-full overflow-y-auto shadow-2xl animate-in slide-in-from-right"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 bg-gdm-blue text-white px-5 py-3 flex items-center justify-between z-10">
          <h3 className="font-semibold">{t('drw.title')}</h3>
          <button onClick={onClose} className="p-1 hover:bg-white/10 rounded">
            <X size={18} />
          </button>
        </div>

        {loading || !r ? (
          <div className="py-20 flex justify-center"><Spinner /></div>
        ) : (
          <div className="p-5 space-y-4">
            <div className="flex items-center justify-between">
              <p className="text-[11px] text-gray-500 font-mono">ID: {r.id.substring(0, 8)}...</p>
              <ReservaStatusBadge status={r.status} />
            </div>

            <Section icon={<Car size={14} />} title={t('drw.section.asset')}>
              <p className="font-semibold text-gdm-blue dark:text-gdm-lime">{r.codigo_interno}</p>
              <p className="text-sm">{r.ativo_descricao}</p>
              {r.placa && <p className="text-xs text-gray-500">{t('disp.plate')}: {r.placa}</p>}
              <p className="text-xs text-gray-500">{t('drw.type')}: {r.tipo_ativo?.replace('_', ' ')}</p>
            </Section>

            <Section icon={<User size={14} />} title={t('drw.section.user')}>
              <p className="font-semibold">{r.usuario_nome || '—'}</p>
              <p className="text-xs text-gray-500">{r.usuario_email || ''}</p>
            </Section>

            <Section icon={<Calendar size={14} />} title={t('drw.section.period')}>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <p className="text-[11px] text-gray-500">{t('drw.start')}</p>
                  <p>{fmt(r.data_hora_inicio)}</p>
                </div>
                <div>
                  <p className="text-[11px] text-gray-500">{t('drw.end')}</p>
                  <p>{fmt(r.data_hora_fim)}</p>
                </div>
              </div>
              <p className="text-xs text-gdm-blue dark:text-gdm-lime mt-2 font-medium">
                <Clock size={11} className="inline" /> {t('drw.duration', { n: horas })}
              </p>
            </Section>

            {r.motivo && (
              <Section icon={<FileText size={14} />} title={t('drw.section.reason')}>
                <p className="text-sm">{r.motivo}</p>
              </Section>
            )}

            {r.observacoes && (
              <Section icon={<FileText size={14} />} title={t('drw.section.notes')}>
                <p className="text-sm whitespace-pre-line">{r.observacoes}</p>
              </Section>
            )}

            <Section icon={<MapPin size={14} />} title={t('drw.section.timeline')}>
              <div className="space-y-1.5 text-xs">
                <Timeline label={t('drw.tl.created')} data={r.criado_em} />
                <Timeline label={t('drw.tl.confirmed')} data={r.confirmado_em} />
                <Timeline label={t('drw.tl.cancelled')} data={r.cancelado_em} />
              </div>
            </Section>

            <div className="pt-4 border-t border-gray-200 dark:border-gdm-blue space-y-2">
              {r.status === 'PENDENTE' && (
                <Button onClick={confirmarAdmin} className="w-full justify-center">
                  <CheckCircle2 size={14} /> {t('drw.confirmAdmin')}
                </Button>
              )}
              {['PENDENTE', 'CONFIRMADA'].includes(r.status) && (
                <Button variant="danger" onClick={cancelarAdmin} className="w-full justify-center">
                  <XCircle size={14} /> {t('drw.cancel')}
                </Button>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function Section({ icon, title, children }: { icon: JSX.Element; title: string; children: React.ReactNode }) {
  return (
    <div className="bg-gray-50 dark:bg-gdm-blue rounded-lg p-3">
      <div className="flex items-center gap-1.5 text-xs font-semibold text-gdm-blue dark:text-gdm-lime mb-1.5">
        {icon} {title}
      </div>
      {children}
    </div>
  );
}

function Timeline({ label, data }: { label: string; data?: string }) {
  if (!data) return null;
  return (
    <div className="flex justify-between">
      <span className="text-gray-500">{label}:</span>
      <span>{format(new Date(data), 'dd/MM/yyyy HH:mm', { locale: ptBR })}</span>
    </div>
  );
}
