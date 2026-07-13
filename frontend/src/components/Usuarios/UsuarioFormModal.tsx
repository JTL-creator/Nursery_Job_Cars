import { FormEvent, useEffect, useState } from 'react';
import Modal from '../UI/Modal';
import Button from '../UI/Button';
import Input from '../UI/Input';
import Select from '../UI/Select';
import { NovoUsuario, PerfilNome, Usuario } from '../../types';
import { criarUsuario, atualizarUsuario } from '../../services/usuarioService';
import { runAction } from '../../hooks/useApiData';
import { useI18n } from '../../hooks/useI18n';
import { Save } from 'lucide-react';

interface Props {
    open: boolean;
    usuario: Usuario | null; // null = criar
    onClose: () => void;
    onSaved: () => void;
}

const PERFIS: PerfilNome[] = ['USUARIO', 'RESPONSAVEL', 'GERENTE', 'ADMINISTRADOR'];

interface FormState {
    nome_completo: string;
    matricula: string;
    email: string;
    telefone: string;
    unidade_lotacao: string;
    perfil: PerfilNome;
    senha: string;
}

const vazio: FormState = {
    nome_completo: '', matricula: '', email: '', telefone: '',
    unidade_lotacao: '', perfil: 'USUARIO', senha: '',
};

export default function UsuarioFormModal({ open, usuario, onClose, onSaved }: Props) {
    const { t } = useI18n();
    const ehEdicao = !!usuario;
    const [form, setForm] = useState<FormState>(vazio);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (usuario) {
            setForm({
                nome_completo: usuario.nome_completo,
                matricula: usuario.matricula || '',
                email: usuario.email,
                telefone: usuario.telefone || '',
                unidade_lotacao: usuario.unidade_lotacao || '',
                perfil: usuario.perfil || 'USUARIO',
                senha: '',
            });
        } else {
            setForm(vazio);
        }
    }, [usuario, open]);

    const upd = <K extends keyof FormState>(k: K) =>
        (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
            setForm((s) => ({ ...s, [k]: e.target.value }));

    const submit = async (e: FormEvent) => {
        e.preventDefault();
        setLoading(true);
        let result;
        if (ehEdicao) {
            const payload: Partial<NovoUsuario> = {
                nome_completo: form.nome_completo,
                matricula: form.matricula,
                email: form.email,
                telefone: form.telefone,
                unidade_lotacao: form.unidade_lotacao,
                perfil: form.perfil,
            };
            result = await runAction(() => atualizarUsuario(usuario!.id, payload), t('usr.toast.updated'));
        } else {
            const payload: NovoUsuario = {
                nome_completo: form.nome_completo,
                matricula: form.matricula,
                email: form.email,
                telefone: form.telefone || undefined,
                unidade_lotacao: form.unidade_lotacao || undefined,
                perfil: form.perfil,
                senha: form.senha || undefined,
            };
            result = await runAction(() => criarUsuario(payload), t('usr.toast.created'));
        }
        setLoading(false);
        if (result) { onSaved(); onClose(); }
    };

    return (
        <Modal
            open={open}
            onClose={onClose}
            title={ehEdicao ? t('usr.editTitle') : t('usr.newTitle')}
            size="md"
        >
            <form onSubmit={submit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <Input
                    label={t('usr.name')}
                    value={form.nome_completo}
                    onChange={upd('nome_completo')}
                    required
                    className="md:col-span-2"
                />
                <Input label={t('usr.registration')} value={form.matricula} onChange={upd('matricula')} required />
                <Input label={t('usr.email')} type="email" value={form.email} onChange={upd('email')} required />
                <Input label={t('usr.phone')} value={form.telefone} onChange={upd('telefone')} />
                <Input label={t('usr.unit')} value={form.unidade_lotacao} onChange={upd('unidade_lotacao')} />
                <Select
                    label={t('usr.role')}
                    value={form.perfil}
                    onChange={upd('perfil')}
                    options={PERFIS.map((p) => ({ value: p, label: t(`role.${p}`) }))}
                />
                {!ehEdicao && (
                    <Input
                        label={t('usr.password')}
                        type="password"
                        value={form.senha}
                        onChange={upd('senha')}
                        placeholder={t('usr.passwordHint')}
                    />
                )}
                <div className="md:col-span-2 flex justify-end gap-2 mt-2">
                    <Button variant="ghost" type="button" onClick={onClose}>{t('common.cancel')}</Button>
                    <Button type="submit" loading={loading}>
                        <Save size={14} /> {ehEdicao ? t('afm.save') : t('afm.create')}
                    </Button>
                </div>
            </form>
        </Modal>
    );
}
