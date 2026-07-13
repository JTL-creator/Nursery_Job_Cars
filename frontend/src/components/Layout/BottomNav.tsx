import { NavLink } from 'react-router-dom';
import { Home, CalendarSearch, CalendarCheck, ClipboardList } from 'lucide-react';
import clsx from 'clsx';
import { useI18n } from '../../hooks/useI18n';

const items = [
  { to: '/home', labelKey: 'bnav.home', icon: <Home size={20} /> },
  { to: '/disponibilidade', labelKey: 'bnav.availability', icon: <CalendarSearch size={20} /> },
  { to: '/reservas', labelKey: 'bnav.reservations', icon: <CalendarCheck size={20} /> },
  { to: '/checklists', labelKey: 'bnav.checklists', icon: <ClipboardList size={20} /> },
];

export default function BottomNav() {
  const { t } = useI18n();
  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-gdm-blue text-white z-40 border-t border-white/10">
      <div className="flex justify-around">
        {items.map((it) => (
          <NavLink
            key={it.to}
            to={it.to}
            className={({ isActive }) =>
              clsx(
                'flex-1 flex flex-col items-center gap-1 py-2 text-[10px]',
                isActive ? 'text-gdm-lime' : 'text-white/80'
              )
            }
          >
            {it.icon}
            <span>{t(it.labelKey)}</span>
          </NavLink>
        ))}
      </div>
    </nav>
  );
}
