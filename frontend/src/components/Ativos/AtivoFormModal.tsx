import { FormEvent, useEffect, useRef, useState } from 'react';
import Modal from '../UI/Modal';
import Button from '../UI/Button';
import Input from '../UI/Input';
import Select from '../UI/Select';
import { Ativo, NovoAtivo, TipoAtivo, Usuario } from '../../types';
import { criarAtivo, atualizarAtivo, uploadFotoAtivo } from '../../services/ativoService';
import { listarResponsaveis } from '../../services/usuarioService';
import { mediaUrl } from '../../services/api';
import { runAction } from '../../hooks/useApiData';
import { useI18n } from '../../hooks/useI18n';
import toast from 'react-hot-toast';
import { Save, Upload, ImageIcon, X } from 'lucide-react';

interface Props {
  open: boolean;
  ativo: Ativo | null; // null = criar; preenchido = editar
  onClose: () => void;
  onSaved: () => void;
}

const TIPOS: { value: TipoAtivo; labelKey: string }[] = [
  { value: 'VEICULO', labelKey: 'tpl.type.vehicle' },
  { value: 'MAQUINA_AGRICOLA', labelKey: 'tpl.type.machine' },
  { value: 'IMPLEMENTO', labelKey: 'tpl.type.implement' },
];

export default function AtivoFormModal({ open, ativo, onClose, onSaved }: Props) {
  const { t } = useI18n();
  const ehEdicao = !!ativo;
  const [responsaveis, setResponsaveis] = useState<Usuario[]>([]);
  const fileRef = useRef<HTMLInputElement>(null);
  const [uploadingFoto, setUploadingFoto] = useState(false);
  const [form, setForm] = useState<NovoAtivo>({
    codigo_interno: '',
    descricao: '',
    tipo_ativo: 'VEICULO',
    sub_tipo: '',
    placa: '',
    patrimonio: '',
    unidade: '',
    observacoes: '',
    responsavel_id: '',
    equipe: '',
    foto_url: '',
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!open) return;
    listarResponsaveis()
      .then((r) => setResponsaveis(r.data))
      .catch(() => setResponsaveis([]));
  }, [open]);

  useEffect(() => {
    if (ativo) {
      setForm({
        codigo_interno: ativo.codigo_interno,
        descricao: ativo.descricao,
        tipo_ativo: ativo.tipo_ativo,
        sub_tipo: ativo.sub_tipo || '',
        placa: ativo.placa || '',
        patrimonio: ativo.patrimonio || '',
        unidade: ativo.unidade || '',
        observacoes: ativo.observacoes || '',
        responsavel_id: ativo.responsavel_id || '',
        equipe: ativo.equipe || '',
        foto_url: ativo.foto_url || '',
      });
    } else {
      setForm({
        codigo_interno: '', descricao: '', tipo_ativo: 'VEICULO',
        sub_tipo: '', placa: '', patrimonio: '', unidade: '', observacoes: '',
        responsavel_id: '', equipe: '', foto_url: '',
      });
    }
  }, [ativo, open]);

  const upd = <K extends keyof NovoAtivo>(k: K) =>
    (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
      setForm((s) => ({ ...s, [k]: e.target.value }));

  const onSelecionarFoto = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      setUploadingFoto(true);
      const url = await uploadFotoAtivo(file);
      setForm((s) => ({ ...s, foto_url: url }));
    } catch {
      /* interceptor mostra erro */
    } finally {
      setUploadingFoto(false);
      if (fileRef.current) fileRef.current.value = '';
    }
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (uploadingFoto) { toast.error(t('afm.photoUploading')); return; }
    setLoading(true);
    const payload: NovoAtivo = {
      ...form,
      sub_tipo: form.sub_tipo || undefined,
      placa: form.placa || undefined,
      patrimonio: form.patrimonio || undefined,
      unidade: form.unidade || undefined,
      observacoes: form.observacoes || undefined,
      responsavel_id: form.responsavel_id ? form.responsavel_id : null,
      equipe: form.equipe ? form.equipe : null,
      foto_url: form.foto_url ? form.foto_url : null,
    };
    const result = ehEdicao
      ? await runAction(() => atualizarAtivo(ativo!.id, payload), t('afm.toast.updated'))
      : await runAction(() => criarAtivo(payload), t('afm.toast.created'));
    setLoading(false);
    if (result) { onSaved(); onClose(); }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={ehEdicao ? t('afm.editTitle') : t('afm.newTitle')}
      size="md"
    >
      <form onSubmit={submit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Input
          label={t('afm.code')}
          value={form.codigo_interno}
          onChange={upd('codigo_interno')}
          placeholder="Ex.: VEIC-004"
          required
        />
        <Select
          label={t('afm.type')}
          value={form.tipo_ativo}
          onChange={upd('tipo_ativo')}
          options={TIPOS.map((o) => ({ value: o.value, label: t(o.labelKey) }))}
        />
        <Input
          label={t('afm.desc')}
          value={form.descricao}
          onChange={upd('descricao')}
          placeholder="Ex.: Job Car Toyota Hilux 2024"
          required
          className="md:col-span-2"
        />
        <Input
          label={t('afm.subtype')}
          value={form.sub_tipo}
          onChange={upd('sub_tipo')}
          placeholder="Pickup, Trator, etc."
        />
        <Input
          label={t('afm.unit')}
          value={form.unidade}
          onChange={upd('unidade')}
          placeholder="Porto Nacional - TO"
        />
        <Input
          label={t('afm.plate')}
          value={form.placa}
          onChange={upd('placa')}
          placeholder="ABC1D23"
        />
        <Input
          label={t('afm.patrimony')}
          value={form.patrimonio}
          onChange={upd('patrimonio')}
          placeholder="PAT-1003"
        />
        <Input
          label={t('afm.team')}
          value={form.equipe || ''}
          onChange={upd('equipe')}
          placeholder="Milho, Soja, Agronomia..."
        />
        <div className="md:col-span-2">
          <label className="text-sm font-medium text-gdm-blue dark:text-gray-200">
            {t('afm.photo')}
          </label>
          <div className="mt-1 flex items-center gap-3">
            <div className="w-20 h-20 rounded-lg overflow-hidden bg-gray-100 dark:bg-gdm-blue border border-gray-200 dark:border-gdm-blue flex items-center justify-center shrink-0">
              {form.foto_url ? (
                <img src={mediaUrl(form.foto_url)} alt="" className="w-full h-full object-cover" />
              ) : (
                <ImageIcon size={22} className="text-gray-400" />
              )}
            </div>
            <div className="flex flex-col gap-2">
              <input
                ref={fileRef}
                type="file"
                accept="image/png,image/jpeg,image/webp,image/gif"
                onChange={onSelecionarFoto}
                className="hidden"
              />
              <Button
                type="button"
                variant="ghost"
                loading={uploadingFoto}
                onClick={() => fileRef.current?.click()}
              >
                <Upload size={14} /> {t('afm.uploadPhoto')}
              </Button>
              {form.foto_url && (
                <button
                  type="button"
                  onClick={() => setForm((s) => ({ ...s, foto_url: '' }))}
                  className="text-[11px] text-red-600 flex items-center gap-1 hover:underline"
                >
                  <X size={12} /> {t('afm.removePhoto')}
                </button>
              )}
            </div>
          </div>
        </div>
        <div className="md:col-span-2">
          <Select
            label={t('afm.responsible')}
            value={form.responsavel_id || ''}
            onChange={upd('responsavel_id')}
            options={[
              { value: '', label: t('afm.noResponsible') },
              ...responsaveis.map((u) => ({
                value: u.id,
                label: `${u.nome_completo} (${u.email})`,
              })),
            ]}
          />
          <p className="mt-1 text-[11px] text-gray-500 dark:text-gray-400">
            {t('afm.responsibleHint')}
          </p>
        </div>
        <div className="md:col-span-2">
          <label className="text-sm font-medium text-gdm-blue dark:text-gray-200">
            {t('afm.notes')}
          </label>
          <textarea
            value={form.observacoes}
            onChange={upd('observacoes')}
            rows={3}
            className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue
                       bg-white dark:bg-gdm-blue2 dark:text-white focus:outline-none focus:ring-2 focus:ring-gdm-lime"
          />
        </div>

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
