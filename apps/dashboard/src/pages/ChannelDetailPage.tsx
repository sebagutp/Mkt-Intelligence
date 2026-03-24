import { useParams } from 'react-router-dom';
import { BarChart3 } from 'lucide-react';
import { CHANNEL_LABELS } from '@/lib/constants';
import type { ChannelType } from '@/types/tenant';

export function ChannelDetailPage() {
  const { type } = useParams<{ type: string }>();
  const label = CHANNEL_LABELS[type as ChannelType] ?? type;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
        <BarChart3 size={24} />
        {label}
      </h1>
      <p className="text-gray-500 dark:text-gray-400">
        Channel detail panels will be implemented in HU-008.
      </p>
    </div>
  );
}
