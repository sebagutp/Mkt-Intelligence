import { useState, useRef, useEffect } from 'react';
import { Menu, Moon, Sun, LogOut, User } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useTenant } from '@/hooks/useTenant';

interface HeaderProps {
  onMenuToggle: () => void;
}

export function Header({ onMenuToggle }: HeaderProps) {
  const { user, signOut } = useAuth();
  const tenant = useTenant();
  const [darkMode, setDarkMode] = useState(
    () => document.documentElement.classList.contains('dark'),
  );
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  function toggleDark() {
    const next = !darkMode;
    setDarkMode(next);
    document.documentElement.classList.toggle('dark', next);
    localStorage.setItem('theme', next ? 'dark' : 'light');
  }

  return (
    <header className="sticky top-0 z-30 flex items-center justify-between h-16 px-4 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800">
      <div className="flex items-center gap-3">
        <button
          onClick={onMenuToggle}
          className="md:hidden p-2 rounded text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800"
        >
          <Menu size={20} />
        </button>

        {tenant.branding.logo_url ? (
          <img
            src={tenant.branding.logo_url}
            alt={tenant.branding.product_name}
            className="h-8"
          />
        ) : (
          <span className="text-lg font-bold text-[var(--brand-primary)] hidden md:block">
            {tenant.branding.product_name}
          </span>
        )}
      </div>

      <div className="flex items-center gap-2">
        <button
          onClick={toggleDark}
          className="p-2 rounded text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800"
          title="Toggle dark mode"
        >
          {darkMode ? <Sun size={18} /> : <Moon size={18} />}
        </button>

        <div ref={dropdownRef} className="relative">
          <button
            onClick={() => setDropdownOpen(!dropdownOpen)}
            className="flex items-center gap-2 p-2 rounded hover:bg-gray-100 dark:hover:bg-gray-800"
          >
            <div className="w-8 h-8 rounded-full bg-[var(--brand-primary)]/20 flex items-center justify-center">
              <User size={16} className="text-[var(--brand-primary)]" />
            </div>
            <span className="hidden sm:block text-sm text-gray-700 dark:text-gray-300 max-w-[150px] truncate">
              {user?.email}
            </span>
          </button>

          {dropdownOpen && (
            <div className="absolute right-0 mt-1 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-1">
              <div className="px-3 py-2 text-xs text-gray-500 dark:text-gray-400 truncate">
                {user?.email}
              </div>
              <hr className="border-gray-200 dark:border-gray-700" />
              <button
                onClick={() => {
                  setDropdownOpen(false);
                  signOut();
                }}
                className="flex items-center gap-2 w-full px-3 py-2 text-sm text-red-600 hover:bg-gray-100 dark:hover:bg-gray-700"
              >
                <LogOut size={16} />
                Sign out
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
