// src/components/ui/Skeleton.jsx
import React from 'react';

/**
 * Reusable animated skeleton loader component.
 */
export default function Skeleton({ className = '', variant = 'rect', width, height }) {
  const styles = {};
  if (width) styles.width = width;
  if (height) styles.height = height;

  const typeClass = variant === 'circle' ? 'rounded-full' : 'rounded-[var(--radius-md)]';

  return (
    <div
      style={styles}
      className={`animate-pulse bg-gray-200 dark:bg-slate-700 ${typeClass} ${className}`}
    />
  );
}

export function CardSkeleton() {
  return (
    <div className="p-6 bg-white dark:bg-slate-800 rounded-[var(--radius-xl)] border border-[var(--color-border)] dark:border-slate-700 shadow-[var(--shadow-sm)]">
      <div className="flex justify-between items-start mb-4">
        <Skeleton variant="rect" width="80px" height="24px" />
        <Skeleton variant="circle" width="32px" height="32px" />
      </div>
      <Skeleton variant="rect" className="mb-2" width="140px" height="32px" />
      <Skeleton variant="rect" width="100px" height="16px" />
    </div>
  );
}

export function TableRowSkeleton() {
  return (
    <div className="flex items-center gap-4 py-3 border-b border-[var(--color-border)] dark:border-slate-700 last:border-0">
      <Skeleton variant="circle" width="40px" height="40px" className="flex-shrink-0" />
      <div className="flex-1 space-y-2">
        <Skeleton variant="rect" width="60%" height="16px" />
        <Skeleton variant="rect" width="40%" height="12px" />
      </div>
      <Skeleton variant="rect" width="60px" height="24px" />
    </div>
  );
}
