import { NavLink } from 'react-router-dom';
import {
  Home, CalendarSearch, CalendarCheck, ClipboardList,
  Truck, UserPlus, BarChart3, FileText, Users,
} from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { useI18n } from '../../hooks/useI18n';
import clsx from 'clsx';

interface Item {
  to: string;
  labelKey: string;
  icon: JSX.Element;
  roles?: string[];
}

const items: Item[] = [
  { to: '/home', labelKey: 'nav.home', icon: <Home size={20} /> },
  { to: '/disponibilidade', labelKey: 'nav.disponibilidade', icon: <CalendarSearch size={20} /> },
  { to: '/reservas', labelKey: 'nav.reservas', icon: <CalendarCheck size={20} /> },
  { to: '/checklists', labelKey: 'nav.checklists', icon: <ClipboardList size={20} /> },
  { to: '/ativos', labelKey: 'nav.ativos', icon: <Truck size={20} />, roles: ['ADMINISTRADOR'] },
  { to: '/reservas-admin', labelKey: 'nav.reservasAdmin', icon: <CalendarCheck size={20} />, roles: ['ADMINISTRADOR', 'GERENTE'] },
  { to: '/templates', labelKey: 'nav.templates', icon: <FileText size={20} />, roles: ['ADMINISTRADOR'] },
  { to: '/solicitacoes', labelKey: 'nav.solicitacoes', icon: <UserPlus size={20} />, roles: ['ADMINISTRADOR'] },
  { to: '/usuarios', labelKey: 'nav.usuarios', icon: <Users size={20} />, roles: ['ADMINISTRADOR'] },
  { to: '/analytics', labelKey: 'nav.analytics', icon: <BarChart3 size={20} />, roles: ['ADMINISTRADOR', 'GERENTE'] },
];

export default function Sidebar() {
  const { perfil } = useAuth();
  const { t } = useI18n();

  return (
    <aside
      className={clsx(
        'group fixed top-0 left-0 h-full bg-gdm-blue text-white z-40',
        'transition-all duration-300 ease-out',
        'w-[60px] hover:w-[240px] overflow-hidden shadow-lg',
        'hidden md:flex flex-col'
      )}
    >
      <div className="flex items-center gap-3 px-4 py-5 border-b border-white/10">
        <img
          src="/favicon.svg"
          alt="GDM Job Cars"
          className="w-9 h-9 rounded-lg shrink-0 shadow"
        />
        <span className="font-semibold opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
          GDM Job Cars
        </span>
      </div>
      <nav className="flex-1 py-3 overflow-y-auto">
        {items.map((it) => {
          if (it.roles && (!perfil || !it.roles.includes(perfil))) return null;
          return (
            <NavLink
              key={it.to}
              to={it.to}
              className={({ isActive }) =>
                clsx(
                  'flex items-center gap-3 px-4 py-3 text-sm transition-colors',
                  'hover:bg-white/10',
                  isActive && 'bg-white/10 border-l-4 border-gdm-lime'
                )
              }
            >
              <span className="shrink-0">{it.icon}</span>
              <span className="opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                {t(it.labelKey)}
              </span>
            </NavLink>
          );
        })}
      </nav>
      <div className="px-4 py-3 text-[10px] opacity-0 group-hover:opacity-100 transition-opacity border-t border-white/10">
        v0.3.0 — Executive
      </div>
    </aside>
  );
}
