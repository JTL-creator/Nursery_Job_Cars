import { Sun, Moon, LogOut, User } from 'lucide-react';
import { useTheme } from '../../hooks/useTheme';
import { useAuth } from '../../hooks/useAuth';
import { useI18n } from '../../hooks/useI18n';

export default function Navbar() {
  const { theme, toggleTheme } = useTheme();
  const { user, perfil, logout } = useAuth();
  const { lang, setLang, t } = useI18n();

  return (
    <header className="sticky top-0 z-30 bg-white dark:bg-gdm-blue2 border-b border-gray-200 dark:border-gdm-blue px-4 md:px-6 py-3 flex items-center justify-between shadow-sm">
      <div className="flex items-center gap-3">
        <img
          src="/favicon.svg"
          alt=""
          className="w-9 h-9 rounded-lg shrink-0 shadow-sm hidden sm:block"
        />
        <div>
          <h1 className="text-base md:text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
            GDM Job Cars
          </h1>
          <p className="text-[11px] text-gray-500 dark:text-gray-400">
            {t('app.subtitle')}
          </p>
        </div>
      </div>

      <div className="flex items-center gap-2 md:gap-3">
        <div
          className="flex items-center rounded-lg border border-gray-200 dark:border-gdm-blue overflow-hidden text-[11px] font-bold select-none"
          role="group"
          aria-label={t('common.language')}
        >
          <button
            onClick={() => setLang('en')}
            className={
              'px-2.5 py-1.5 transition-colors ' +
              (lang === 'en'
                ? 'bg-gdm-lime text-gdm-blue'
                : 'text-gray-500 dark:text-gray-300 hover:bg-black/5 dark:hover:bg-white/10')
            }
          >
            EN
          </button>
          <button
            onClick={() => setLang('pt')}
            className={
              'px-2.5 py-1.5 transition-colors ' +
              (lang === 'pt'
                ? 'bg-gdm-lime text-gdm-blue'
                : 'text-gray-500 dark:text-gray-300 hover:bg-black/5 dark:hover:bg-white/10')
            }
          >
            PT
          </button>
        </div>
        <button
          onClick={toggleTheme}
          className="p-2 rounded-lg hover:bg-black/5 dark:hover:bg-white/10 text-gdm-blue dark:text-gdm-lime"
          aria-label={t('common.theme')}
        >
          {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
        </button>

        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-gray-100 dark:bg-gdm-blue">
          <User size={16} className="text-gdm-blue dark:text-gdm-lime" />
          <div className="leading-tight">
            <p className="text-xs font-semibold text-gdm-blue dark:text-white">
              {user?.nome_completo.split(' ')[0]}
            </p>
            <p className="text-[10px] text-gray-500 dark:text-gray-300">{perfil}</p>
          </div>
        </div>

        <button
          onClick={logout}
          className="p-2 rounded-lg hover:bg-red-50 text-red-600 dark:hover:bg-red-900/30"
          aria-label={t('common.logout')}
          title={t('common.logout')}
        >
          <LogOut size={18} />
        </button>
      </div>
    </header>
  );
}
