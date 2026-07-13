import Modal from './Modal';
import Button from './Button';
import { useI18n } from '../../hooks/useI18n';

interface Props {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'primary' | 'danger';
  onConfirm: () => void;
  onClose: () => void;
}

export default function ConfirmDialog({
  open, title, message, confirmLabel, cancelLabel,
  variant = 'primary', onConfirm, onClose,
}: Props) {
  const { t } = useI18n();
  return (
    <Modal
      open={open}
      onClose={onClose}
      title={title}
      size="sm"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>{cancelLabel ?? t('common.cancel')}</Button>
          <Button
            variant={variant === 'danger' ? 'danger' : 'primary'}
            onClick={() => { onConfirm(); onClose(); }}
          >
            {confirmLabel ?? t('common.confirm')}
          </Button>
        </>
      }
    >
      <p className="text-sm text-gray-700 dark:text-gray-200">{message}</p>
    </Modal>
  );
}
