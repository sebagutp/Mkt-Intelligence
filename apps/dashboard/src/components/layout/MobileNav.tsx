import { NavLink } from 'react-router-dom';
import { LayoutDashboard, BarChart3, Lightbulb, FileText, Settings } from 'lucide-react';

const items = [
  { to: '/', icon: LayoutDashboard, label: 'Overview' },
  { to: '/channel/google_ads', icon: BarChart3, label: 'Channels' },
  { to: '/insights', icon: Lightbulb, label: 'Insights' },
  { to: '/reports', icon: FileText, label: 'Reports' },
  { to: '/settings', icon: Settings, label: 'Settings' },
] as const;

export function MobileNav() {
  return (
    <nav className="fixed bottom-0 inset-x-0 z-30 bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800 md:hidden">
      <div className="flex items-center justify-around h-14">
        {items.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex flex-col items-center gap-0.5 text-[10px] ${
                isActive
                  ? 'text-[var(--brand-primary)]'
                  : 'text-gray-500 dark:text-gray-400'
              }`
            }
          >
            <Icon size={20} />
            {label}
          </NavLink>
        ))}
      </div>
    </nav>
  );
}
