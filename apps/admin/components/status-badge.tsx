export function StatusBadge({ value }: { value?: string | null }) {
  return <span className={`status status-${value ?? 'none'}`}>{value ?? 'none'}</span>;
}
