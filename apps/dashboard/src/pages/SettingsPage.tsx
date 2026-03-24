import { Settings } from 'lucide-react';

export function SettingsPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
        <Settings size={24} />
        Settings
      </h1>
      <p className="text-gray-500 dark:text-gray-400">
        Settings page will be implemented in a future sprint.
      </p>
    </div>
  );
}
