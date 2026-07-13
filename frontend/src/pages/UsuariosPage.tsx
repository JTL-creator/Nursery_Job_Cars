import { useEffect, useMemo, useState } from 'react';
import { Plus, RefreshCw, Search, Edit2, KeyRound } from 'lucide-react';
import Card from '../components/UI/Card';
import Button from '../components/UI/Button';
import Input from '../components/UI/Input';
import Spinner from '../components/UI/Spinner';
import EmptyState from '../components/UI/EmptyState';
import ConfirmDialog from '../components/UI/ConfirmDialog';
import UsuarioFormModal from '../components/Usuarios/UsuarioFormModal';
import { PerfilNome, StatusUsuario, Usuario } from '../types';
import {
    listarUsuarios, alterarStatusUsuario, redefinirSenhaUsuario,
} from '../services/usuarioService';
import { useDebounce } from '../hooks/useDebounce';
import { runAction } from '../hooks/useApiData';
import { useI18n } from '../hooks/useI18n';

const PERFIS: PerfilNome[] = ['USUARIO', 'RESPONSAVEL', 'GERENTE', 'ADMINISTRADOR', 'VIGILANTE'];
const STATUS: StatusUsuario[] = ['ATIVO', 'INATIVO', 'BLOQUEADO'];

export default function UsuariosPage() {
    const { t } = useI18n();
    const [items, setItems] = useState<Usuario[]>([]);
    const [loading, setLoading] = useState(true);

    const [busca, setBusca] = useState('');
    const buscaDeb = useDebounce(busca, 350);
    const [perfil, setPerfil] = useState<PerfilNome | ''>('');
    const [status, setStatus] = useState<StatusUsuario | ''>('');

    const [modalAberto, setModalAberto] = useState(false);
    const [usuarioEdit, setUsuarioEdit] = useState<Usuario | null>(null);
    const [resetAlvo, setResetAlvo] = useState<Usuario | null>(null);

    const filtros = useMemo(() => ({
        q: buscaDeb || undefined,
        perfil: perfil || undefined,
        status: status || undefined,
    }), [buscaDeb, perfil, status]);

    const carregar = async () => {
        try {
            setLoading(true);
            const r = await listarUsuarios(filtros);
            setItems(r.data);
        } catch {/* interceptor */ } finally {
            setLoading(false);
        }
    };

    useEffect(() => { carregar(); /* eslint-disable-next-line */ }, [JSON.stringify(filtros)]);

    const novo = () => { setUsuarioEdit(null); setModalAberto(true); };
    const editar = (u: Usuario) => { setUsuarioEdit(u); setModalAberto(true); };

    const mudarStatus = async (u: Usuario, novoStatus: StatusUsuario) => {
        if (novoStatus === u.status) return;
        const ok = await runAction(() => alterarStatusUsuario(u.id, novoStatus), t('usr.toast.statusUpdated'));
        if (ok) carregar();
    };

    const confirmarReset = async () => {
        if (!resetAlvo) return;
        const ok = await runAction(() => redefinirSenhaUsuario(resetAlvo.id), t('usr.toast.passwordReset'));
        if (ok) setResetAlvo(null);
    };

    return (
        <div className="flex flex-col gap-4">
            <Card>
                <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
                    <div>
                        <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
                            {t('usr.title')}
                        </h2>
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                            {items.length} {items.length === 1 ? t('usr.count.one') : t('usr.count.other')}
                        </p>
                    </div>
                    <div className="flex gap-2">
                        <Button variant="ghost" onClick={carregar}>
                            <RefreshCw size={14} /> {t('common.refresh')}
                        </Button>
                        <Button onClick={novo}>
                            <Plus size={14} /> {t('usr.new')}
                        </Button>
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mt-4">
                    <div className="relative">
                        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                        <Input
                            placeholder={t('usr.search')}
                            value={busca}
                            onChange={(e) => setBusca(e.target.value)}
                            className="!pl-9"
                        />
                    </div>
                    <select
                        value={perfil}
                        onChange={(e) => setPerfil(e.target.value as PerfilNome | '')}
                        className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm"
                    >
                        <option value="">{t('usr.filter.allRoles')}</option>
                        {PERFIS.map((p) => <option key={p} value={p}>{t(`role.${p}`)}</option>)}
                    </select>
                    <select
                        value={status}
                        onChange={(e) => setStatus(e.target.value as StatusUsuario | '')}
                        className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm"
                    >
                        <option value="">{t('usr.filter.allStatus')}</option>
                        {STATUS.map((s) => <option key={s} value={s}>{t(`ustatus.${s}`)}</option>)}
                    </select>
                </div>
            </Card>

            <Card className="!p-0 overflow-hidden">
                {loading ? (
                    <div className="py-10 flex justify-center"><Spinner /></div>
                ) : items.length === 0 ? (
                    <EmptyState title={t('usr.empty.title')} description={t('usr.empty.desc')} />
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead className="bg-gdm-blue text-white text-left">
                                <tr>
                                    <th className="px-4 py-3">{t('usr.col.name')}</th>
                                    <th className="px-4 py-3 hidden md:table-cell">{t('usr.col.registration')}</th>
                                    <th className="px-4 py-3 hidden lg:table-cell">{t('usr.col.email')}</th>
                                    <th className="px-4 py-3 hidden xl:table-cell">{t('usr.col.unit')}</th>
                                    <th className="px-4 py-3">{t('usr.col.role')}</th>
                                    <th className="px-4 py-3">{t('usr.col.status')}</th>
                                    <th className="px-4 py-3 text-right">{t('ativ.col.actions')}</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-gdm-blue">
                                {items.map((u) => (
                                    <tr key={u.id} className="hover:bg-gray-50 dark:hover:bg-gdm-blue/40">
                                        <td className="px-4 py-3">
                                            <p className="font-medium text-gdm-blue dark:text-white">{u.nome_completo}</p>
                                            <p className="lg:hidden text-[11px] text-gray-500">{u.email}</p>
                                        </td>
                                        <td className="px-4 py-3 hidden md:table-cell font-mono text-xs">{u.matricula || '—'}</td>
                                        <td className="px-4 py-3 hidden lg:table-cell">{u.email}</td>
                                        <td className="px-4 py-3 hidden xl:table-cell">{u.unidade_lotacao || '—'}</td>
                                        <td className="px-4 py-3">
                                            <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-gdm-lime/20 text-gdm-blue dark:text-gdm-lime">
                                                {t(`role.${u.perfil || 'USUARIO'}`)}
                                            </span>
                                        </td>
                                        <td className="px-4 py-3">
                                            <select
                                                value={u.status || 'ATIVO'}
                                                onChange={(e) => mudarStatus(u, e.target.value as StatusUsuario)}
                                                className="text-xs rounded-lg border border-gray-300 dark:border-gdm-blue bg-transparent dark:text-white px-1.5 py-1 focus:outline-none"
                                            >
                                                {STATUS.map((s) => <option key={s} value={s}>{t(`ustatus.${s}`)}</option>)}
                                            </select>
                                        </td>
                                        <td className="px-4 py-3">
                                            <div className="flex justify-end gap-1">
                                                <button
                                                    onClick={() => editar(u)}
                                                    className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-700"
                                                    title={t('usr.edit')}
                                                >
                                                    <Edit2 size={14} />
                                                </button>
                                                <button
                                                    onClick={() => setResetAlvo(u)}
                                                    className="p-1.5 rounded-lg hover:bg-amber-100 text-amber-700"
                                                    title={t('usr.resetPassword')}
                                                >
                                                    <KeyRound size={14} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </Card>

            <UsuarioFormModal
                open={modalAberto}
                usuario={usuarioEdit}
                onClose={() => setModalAberto(false)}
                onSaved={carregar}
            />

            <ConfirmDialog
                open={!!resetAlvo}
                title={t('usr.resetTitle')}
                message={t('usr.resetMsg', { name: resetAlvo?.nome_completo || '', registration: resetAlvo?.matricula || '' })}
                confirmLabel={t('usr.resetPassword')}
                variant="danger"
                onConfirm={confirmarReset}
                onClose={() => setResetAlvo(null)}
            />
        </div>
    );
}
