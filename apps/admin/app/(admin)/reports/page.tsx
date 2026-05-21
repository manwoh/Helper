import { StatusBadge } from '@/components/status-badge';
import { adminSupabase } from '@/lib/supabase/admin';

import { updateReportAction } from '../actions';

export default async function ReportsPage() {
  const { data: reports } = await adminSupabase
    .from('reports')
    .select('id, target_type, target_id, reason, details, status, resolution, created_at, reporter:reporter_id(display_name)')
    .order('created_at', { ascending: false })
    .limit(120);

  return (
    <>
      <div className="page-head">
        <div>
          <h1>举报处理</h1>
          <p>处理用户或任务举报，必要时到用户/任务页执行封禁或隐藏。</p>
        </div>
      </div>

      <section className="panel">
        <table>
          <thead>
            <tr>
              <th>举报</th>
              <th>目标</th>
              <th>状态</th>
              <th>处理</th>
            </tr>
          </thead>
          <tbody>
            {(reports ?? []).map((report) => {
              const reporter = Array.isArray(report.reporter) ? report.reporter[0] : report.reporter;
              return (
                <tr key={report.id}>
                  <td>
                    <strong>{report.reason}</strong>
                    <div>{report.details || '-'}</div>
                    <div className="muted">
                      举报人：{reporter?.display_name ?? '未知'} ·{' '}
                      {new Date(report.created_at).toLocaleString('zh-CN')}
                    </div>
                  </td>
                  <td>
                    {report.target_type}
                    <div className="muted">{report.target_id}</div>
                  </td>
                  <td>
                    <StatusBadge value={report.status} />
                    {report.resolution ? <div className="muted">{report.resolution}</div> : null}
                  </td>
                  <td>
                    <form className="actions" action={updateReportAction}>
                      <input type="hidden" name="reportId" value={report.id} />
                      <select name="status" defaultValue={report.status}>
                        <option value="reviewing">reviewing</option>
                        <option value="resolved">resolved</option>
                        <option value="rejected">rejected</option>
                      </select>
                      <input name="resolution" placeholder="处理结果" />
                      <button className="button" type="submit">
                        保存
                      </button>
                    </form>
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
