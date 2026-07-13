import { Link } from 'react-router-dom';
import { useI18n } from '../hooks/useI18n';

export default function NotFoundPage() {
  const { t } = useI18n();
  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-gradient-to-br from-gdm-blue to-gdm-blue2 text-white">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gdm-lime">404</h1>
        <p className="mt-2 text-lg">{t('nf.title')}</p>
        <Link to="/home" className="inline-block mt-5 px-4 py-2 bg-gdm-lime text-gdm-blue rounded-lg font-medium">
          {t('nf.back')}
        </Link>
      </div>
    </div>
  );
}
