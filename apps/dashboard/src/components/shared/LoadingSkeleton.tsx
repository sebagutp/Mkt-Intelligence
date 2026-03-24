interface LoadingSkeletonProps {
  type?: 'text' | 'chart' | 'kpi-grid' | 'card';
  className?: string;
}

function Pulse({ className }: { className: string }) {
  return (
    <div
      className={`animate-pulse rounded bg-gray-200 dark:bg-gray-700 ${className}`}
    />
  );
}

export function LoadingSkeleton({ type = 'text', className = '' }: LoadingSkeletonProps) {
  switch (type) {
    case 'kpi-grid':
      return (
        <div className={`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 ${className}`}>
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="p-4 rounded-lg border border-gray-200 dark:border-gray-700 space-y-3">
              <Pulse className="h-3 w-20" />
              <Pulse className="h-8 w-28" />
              <Pulse className="h-3 w-16" />
            </div>
          ))}
        </div>
      );

    case 'chart':
      return (
        <div className={`rounded-lg border border-gray-200 dark:border-gray-700 p-4 space-y-3 ${className}`}>
          <Pulse className="h-4 w-32" />
          <Pulse className="h-48 w-full" />
        </div>
      );

    case 'card':
      return (
        <div className={`rounded-lg border border-gray-200 dark:border-gray-700 p-4 space-y-3 ${className}`}>
          <Pulse className="h-4 w-24" />
          <Pulse className="h-6 w-36" />
        </div>
      );

    case 'text':
    default:
      return <Pulse className={`h-4 w-full ${className}`} />;
  }
}
