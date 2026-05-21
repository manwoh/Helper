import { adminSupabase } from '@/lib/supabase/admin';

import { saveCategoryAction } from '../actions';

export default async function CategoriesPage() {
  const { data: categories } = await adminSupabase
    .from('categories')
    .select('id, parent_id, task_type, name, slug, description, sort_order, is_active')
    .order('sort_order', { ascending: true });

  const parents = (categories ?? []).filter((category) => !category.parent_id);

  return (
    <>
      <div className="page-head">
        <div>
          <h1>分类管理</h1>
          <p>维护任务入口、分类和子分类。</p>
        </div>
      </div>

      <div className="two-col">
        <section className="panel">
          <table>
            <thead>
              <tr>
                <th>分类</th>
                <th>类型</th>
                <th>排序</th>
                <th>状态</th>
              </tr>
            </thead>
            <tbody>
              {(categories ?? []).map((category) => (
                <tr key={category.id}>
                  <td>
                    <strong>{category.name}</strong>
                    <div className="muted">{category.slug}</div>
                    {category.parent_id ? <div className="muted">子分类</div> : null}
                  </td>
                  <td>{category.task_type || '-'}</td>
                  <td>{category.sort_order}</td>
                  <td>{category.is_active ? '启用' : '停用'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>

        <section className="panel panel-pad">
          <h2>新增分类</h2>
          <form action={saveCategoryAction}>
            <label className="field">
              父分类
              <select name="parentId">
                <option value="">无，作为一级分类</option>
                {parents.map((category) => (
                  <option key={category.id} value={category.id}>
                    {category.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="field">
              任务类型
              <select name="taskType" defaultValue="help">
                <option value="help">help</option>
                <option value="answer">answer</option>
                <option value="find_item">find_item</option>
                <option value="resource">resource</option>
              </select>
            </label>
            <label className="field">
              名称
              <input name="name" required />
            </label>
            <label className="field">
              Slug
              <input name="slug" required />
            </label>
            <label className="field">
              描述
              <textarea name="description" rows={3} />
            </label>
            <label className="field">
              排序
              <input name="sortOrder" type="number" defaultValue={0} />
            </label>
            <div style={{ marginTop: 14 }}>
              <button className="button" type="submit">
                保存分类
              </button>
            </div>
          </form>
        </section>
      </div>
    </>
  );
}
