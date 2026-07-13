import { FormEvent, useEffect, useState } from 'react';
import Modal from '../UI/Modal';
import Button from '../UI/Button';
import Input from '../UI/Input';
import Select from '../UI/Select';
import {
    ChecklistTemplate, EtapaChecklist, NovoTemplate, TemplateItemInput, TipoAtivo, TipoCampo,
} from '../../types';
import { criarTemplate, atualizarTemplate } from '../../services/checklistService';
import { runAction } from '../../hooks/useApiData';
import { useI18n } from '../../hooks/useI18n';
import toast from 'react-hot-toast';
import { Plus, Trash2, ChevronUp, ChevronDown, Save } from 'lucide-react';

interface Props {
    open: boolean;
    template: ChecklistTemplate | null; // null = criar
    onClose: () => void;
    onSaved: () => void;
}

interface ItemDraft {
    uid: number;
    descricao: string;
    tipo_campo: TipoCampo;
    obrigatorio: boolean;
    opcoes: string; // separadas por virgula (apenas para selecao)
}

const TIPOS: TipoAtivo[] = ['VEICULO', 'MAQUINA_AGRICOLA', 'IMPLEMENTO'];
const ETAPAS: EtapaChecklist[] = ['RETIRADA', 'DEVOLUCAO'];
const CAMPOS: TipoCampo[] = ['texto', 'numero', 'booleano', 'selecao', 'data', 'observacao'];

let _uid = 1;
const novoItem = (): ItemDraft => ({
    uid: _uid++, descricao: '', tipo_campo: 'texto', obrigatorio: false, opcoes: '',
});

export default function TemplateFormModal({ open, template, onClose, onSaved }: Props) {
    const { t } = useI18n();
    const ehEdicao = !!template;
    const [nome, setNome] = useState('');
    const [tipo, setTipo] = useState<TipoAtivo>('VEICULO');
    const [etapa, setEtapa] = useState<EtapaChecklist>('RETIRADA');
    const [itens, setItens] = useState<ItemDraft[]>([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (!open) return;
        if (template) {
            setNome(template.nome);
            setTipo(template.tipo_ativo);
            setEtapa(template.etapa);
            setItens(
                (template.itens || []).map((it) => ({
                    uid: _uid++,
                    descricao: it.descricao,
                    tipo_campo: it.tipo_campo,
                    obrigatorio: it.obrigatorio,
                    opcoes: (it.opcoes_json?.opcoes || []).join(', '),
                }))
            );
        } else {
            setNome('');
            setTipo('VEICULO');
            setEtapa('RETIRADA');
            setItens([novoItem()]);
        }
    }, [open, template]);

    const updItem = (uid: number, patch: Partial<ItemDraft>) =>
        setItens((arr) => arr.map((it) => (it.uid === uid ? { ...it, ...patch } : it)));

    const removeItem = (uid: number) =>
        setItens((arr) => arr.filter((it) => it.uid !== uid));

    const mover = (index: number, dir: -1 | 1) => {
        setItens((arr) => {
            const novo = [...arr];
            const alvo = index + dir;
            if (alvo < 0 || alvo >= novo.length) return arr;
            [novo[index], novo[alvo]] = [novo[alvo], novo[index]];
            return novo;
        });
    };

    const submit = async (e: FormEvent) => {
        e.preventDefault();
        const validos = itens.filter((it) => it.descricao.trim());
        if (!nome.trim()) { toast.error(t('tf.err.name')); return; }
        if (validos.length === 0) { toast.error(t('tf.err.items')); return; }

        const payloadItens: TemplateItemInput[] = validos.map((it, idx) => ({
            descricao: it.descricao.trim(),
            tipo_campo: it.tipo_campo,
            obrigatorio: it.obrigatorio,
            ordem: idx + 1,
            opcoes: it.tipo_campo === 'selecao'
                ? it.opcoes.split(',').map((o) => o.trim()).filter(Boolean)
                : undefined,
        }));

        // valida opcoes de selecao
        for (const it of payloadItens) {
            if (it.tipo_campo === 'selecao' && (!it.opcoes || it.opcoes.length === 0)) {
                toast.error(t('tf.err.options'));
                return;
            }
        }

        setLoading(true);
        let result;
        if (ehEdicao) {
            const payload: Partial<NovoTemplate> = { nome: nome.trim(), tipo_ativo: tipo, etapa, itens: payloadItens };
            result = await runAction(() => atualizarTemplate(template!.id, payload), t('tf.toast.updated'));
        } else {
            const payload: NovoTemplate = { nome: nome.trim(), tipo_ativo: tipo, etapa, itens: payloadItens };
            result = await runAction(() => criarTemplate(payload), t('tf.toast.created'));
        }
        setLoading(false);
        if (result) { onSaved(); onClose(); }
    };

    return (
        <Modal
            open={open}
            onClose={onClose}
            title={ehEdicao ? t('tf.editTitle') : t('tf.newTitle')}
            size="lg"
        >
            <form onSubmit={submit} className="flex flex-col gap-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                    <Input label={t('tf.name')} value={nome} onChange={(e) => setNome(e.target.value)} required />
                    <Select
                        label={t('tf.type')}
                        value={tipo}
                        onChange={(e) => setTipo(e.target.value as TipoAtivo)}
                        options={TIPOS.map((v) => ({ value: v, label: t(`tf.type.${v}`) }))}
                    />
                    <Select
                        label={t('tf.stage')}
                        value={etapa}
                        onChange={(e) => setEtapa(e.target.value as EtapaChecklist)}
                        options={ETAPAS.map((v) => ({ value: v, label: t(`tf.stage.${v}`) }))}
                    />
                </div>

                <div className="flex items-center justify-between">
                    <p className="text-sm font-semibold text-gdm-blue dark:text-gdm-lime">
                        {t('tf.fields')} ({itens.filter((i) => i.descricao.trim()).length})
                    </p>
                    <Button type="button" variant="ghost" onClick={() => setItens((a) => [...a, novoItem()])}>
                        <Plus size={14} /> {t('tf.addField')}
                    </Button>
                </div>

                <div className="flex flex-col gap-2">
                    {itens.length === 0 && (
                        <p className="text-xs text-gray-500 py-4 text-center">{t('tf.noFields')}</p>
                    )}
                    {itens.map((it, idx) => (
                        <div
                            key={it.uid}
                            className="rounded-xl border border-gray-200 dark:border-gdm-blue p-3 bg-gray-50 dark:bg-gdm-blue/30"
                        >
                            <div className="flex items-start gap-2">
                                <div className="flex flex-col pt-6">
                                    <button
                                        type="button"
                                        onClick={() => mover(idx, -1)}
                                        disabled={idx === 0}
                                        className="text-gray-400 hover:text-gdm-blue disabled:opacity-30"
                                        title={t('tf.moveUp')}
                                    >
                                        <ChevronUp size={16} />
                                    </button>
                                    <button
                                        type="button"
                                        onClick={() => mover(idx, 1)}
                                        disabled={idx === itens.length - 1}
                                        className="text-gray-400 hover:text-gdm-blue disabled:opacity-30"
                                        title={t('tf.moveDown')}
                                    >
                                        <ChevronDown size={16} />
                                    </button>
                                </div>

                                <div className="flex-1 grid grid-cols-1 md:grid-cols-12 gap-2 items-end">
                                    <div className="md:col-span-6">
                                        <Input
                                            label={`${idx + 1}. ${t('tf.fieldLabel')}`}
                                            value={it.descricao}
                                            onChange={(e) => updItem(it.uid, { descricao: e.target.value })}
                                            placeholder={t('tf.fieldPlaceholder')}
                                        />
                                    </div>
                                    <div className="md:col-span-4">
                                        <Select
                                            label={t('tf.fieldType')}
                                            value={it.tipo_campo}
                                            onChange={(e) => updItem(it.uid, { tipo_campo: e.target.value as TipoCampo })}
                                            options={CAMPOS.map((c) => ({ value: c, label: t(`tc.field.${c}`) }))}
                                        />
                                    </div>
                                    <div className="md:col-span-2 flex items-center gap-2 pb-2">
                                        <label className="flex items-center gap-1.5 text-xs font-medium text-gdm-blue dark:text-gray-200 cursor-pointer">
                                            <input
                                                type="checkbox"
                                                checked={it.obrigatorio}
                                                onChange={(e) => updItem(it.uid, { obrigatorio: e.target.checked })}
                                                className="accent-gdm-lime w-4 h-4"
                                            />
                                            {t('tf.required')}
                                        </label>
                                        <button
                                            type="button"
                                            onClick={() => removeItem(it.uid)}
                                            className="ml-auto p-1.5 rounded-lg text-red-600 hover:bg-red-100"
                                            title={t('tf.removeField')}
                                        >
                                            <Trash2 size={14} />
                                        </button>
                                    </div>

                                    {it.tipo_campo === 'selecao' && (
                                        <div className="md:col-span-12">
                                            <Input
                                                label={t('tf.options')}
                                                value={it.opcoes}
                                                onChange={(e) => updItem(it.uid, { opcoes: e.target.value })}
                                                placeholder={t('tf.optionsPlaceholder')}
                                            />
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                <div className="flex justify-end gap-2 pt-2 border-t border-gray-200 dark:border-gdm-blue">
                    <Button variant="ghost" type="button" onClick={onClose}>{t('common.cancel')}</Button>
                    <Button type="submit" loading={loading}>
                        <Save size={14} /> {ehEdicao ? t('afm.save') : t('afm.create')}
                    </Button>
                </div>
            </form>
        </Modal>
    );
}
