import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  BarChart3,
  Lightbulb,
  FileText,
  Settings,
  ChevronDown,
  ChevronRight,
  X,
} from 'lucide-react';
import { useState } from 'react';
import { useTenant } from '@/hooks/useTenant';
import { CHANNEL_LABELS } from '@/lib/constants';

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

const navLinkClass = ({ isActive }: { isActive: boolean }) =>
  `flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
    isActive
      ? 'bg-[var(--brand-primary)]/10 text-[var(--brand-primary)]'
      : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'
  }`;

export function Sidebar({ open, onClose }: SidebarProps) {
  const tenant = useTenant();
  const [channelsOpen, setChannelsOpen] = useState(true);
  const enabledChannels = tenant.channels.filter((c) => c.enabled);

  return (
    <>
      {/* Overlay for mobile */}
      {open && (
        <div
          className="fixed inset-0 z-40 bg-black/50 md:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-50 w-64 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 transform transition-transform duration-200 md:translate-x-0 md:static md:z-auto ${
          open ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex items-center justify-between h-16 px-4 border-b border-gray-200 dark:border-gray-800">
          <span className="text-lg font-bold text-[var(--brand-primary)]">
            {tenant.branding.product_name}
          </span>
          <button
            onClick={onClose}
            className="md:hidden p-1 rounded text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800"
          >
            <X size={20} />
          </button>
        </div>

        <nav className="p-4 space-y-1 overflow-y-auto h-[calc(100%-4rem)]">
          <NavLink to="/" end className={navLinkClass}>
            <LayoutDashboard size={18} />
            Overview
          </NavLink>

          {/* Channels section */}
          <button
            onClick={() => setChannelsOpen(!channelsOpen)}
            className="flex items-center justify-between w-full px-3 py-2 text-sm font-medium text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg"
          >
            <span className="flex items-center gap-3">
              <BarChart3 size={18} />
              Channels
            </span>
            {channelsOpen ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
          </button>

          {channelsOpen && (
            <div className="ml-6 space-y-1">
              {enabledChannels.map((ch) => (
                <NavLink
                  key={ch.id}
                  to={`/channel/${ch.channel_type}`}
                  className={navLinkClass}
                >
                  <span className="w-2 h-2 rounded-full bg-[var(--brand-accent)]" />
                  {ch.label || CHANNEL_LABELS[ch.channel_type]}
                </NavLink>
              ))}
              {enabledChannels.length === 0 && (
                <p className="px-3 py-2 text-xs text-gray-400">
                  No channels configured
                </p>
              )}
            </div>
          )}

          <NavLink to="/insights" className={navLinkClass}>
            <Lightbulb size={18} />
            Insights
          </NavLink>

          <NavLink to="/reports" className={navLinkClass}>
            <FileText size={18} />
            Reports
          </NavLink>

          <NavLink to="/settings" className={navLinkClass}>
            <Settings size={18} />
            Settings
          </NavLink>
        </nav>
      </aside>
    </>
  );
}
