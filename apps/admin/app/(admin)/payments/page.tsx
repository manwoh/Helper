import { StatusBadge } from '@/components/status-badge';
import { adminSupabase } from '@/lib/supabase/admin';

export default async function PaymentsPage() {
  const { data: payments } = await adminSupabase
    .from('payments')
    .select('id, amount, currency, payment_type, status, provider, provider_reference, created_at, profiles:user_id(display_name), tasks:task_id(title)')
    .order('created_at', { ascending: false })
    .limit(120);

  return (
    <>
      <div className="page-head">
        <div>
          <h1>付款记录</h1>
          <p>预留给加急费、任务抽成、认证会员和广告曝光。</p>
        </div>
      </div>

      <section className="panel">
        <table>
          <thead>
            <tr>
              <th>记录</th>
              <th>用户/任务</th>
              <th>金额</th>
              <th>状态</th>
              <th>Provider</th>
            </tr>
          </thead>
          <tbody>
            {(payments ?? []).map((payment) => {
              const profile = Array.isArray(payment.profiles) ? payment.profiles[0] : payment.profiles;
              const task = Array.isArray(payment.tasks) ? payment.tasks[0] : payment.tasks;
              return (
                <tr key={payment.id}>
                  <td>
                    <strong>{payment.payment_type}</strong>
                    <div className="muted">{new Date(payment.created_at).toLocaleString('zh-CN')}</div>
                  </td>
                  <td>
                    {profile?.display_name ?? '-'}
                    <div className="muted">{task?.title ?? '未关联任务'}</div>
                  </td>
                  <td>
                    {payment.currency} {payment.amount}
                  </td>
                  <td>
                    <StatusBadge value={payment.status} />
                  </td>
                  <td>
                    {payment.provider || '-'}
                    <div className="muted">{payment.provider_reference || ''}</div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </section>
    </>
  );
}
