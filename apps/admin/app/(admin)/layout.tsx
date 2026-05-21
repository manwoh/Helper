import { AdminNav } from '@/components/admin-nav';
import { requireAdmin } from '@/lib/auth';

import { logoutAction } from '../login/actions';

export const dynamic = 'force-dynamic';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const admin = await requireAdmin();

  return (
    <div className="admin-shell">
      <AdminNav />
      <main className="admin-main">
        <div className="page-head">
          <div>
            <p className="muted">管理员：{admin.display_name}</p>
          </div>
          <form action={logoutAction}>
            <button className="button secondary" type="submit">
              退出登录
            </button>
          </form>
        </div>
        {children}
      </main>
    </div>
  );
}
