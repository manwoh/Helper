'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';

import { writeAdminLog } from '@/lib/admin-log';
import { adminSupabase } from '@/lib/supabase/admin';
import { requireAdmin } from '@/lib/auth';

const uuid = z.string().uuid();

const taskStatusSchema = z.object({
  taskId: uuid,
  status: z.enum(['open', 'hidden', 'rejected', 'cancelled', 'completed']),
  moderationNote: z.string().max(500).optional()
});

export async function updateTaskStatusAction(formData: FormData) {
  const admin = await requireAdmin();
  const input = taskStatusSchema.parse({
    taskId: formData.get('taskId'),
    status: formData.get('status'),
    moderationNote: formData.get('moderationNote') || undefined
  });

  await adminSupabase
    .from('tasks')
    .update({
      status: input.status,
      moderation_note: input.moderationNote ?? null
    })
    .eq('id', input.taskId);

  await writeAdminLog({
    adminId: admin.id,
    action: 'task.status.update',
    entityType: 'task',
    entityId: input.taskId,
    details: input
  });

  revalidatePath('/tasks');
}

const banUserSchema = z.object({
  userId: uuid,
  reason: z.string().min(2).max(300)
});

export async function banUserAction(formData: FormData) {
  const admin = await requireAdmin();
  const input = banUserSchema.parse({
    userId: formData.get('userId'),
    reason: formData.get('reason')
  });

  await adminSupabase
    .from('profiles')
    .update({
      is_blocked: true,
      blocked_reason: input.reason,
      blocked_at: new Date().toISOString()
    })
    .eq('id', input.userId);

  await writeAdminLog({
    adminId: admin.id,
    action: 'user.ban',
    entityType: 'user',
    entityId: input.userId,
    details: { reason: input.reason }
  });

  revalidatePath('/users');
}

export async function unbanUserAction(formData: FormData) {
  const admin = await requireAdmin();
  const userId = uuid.parse(formData.get('userId'));

  await adminSupabase
    .from('profiles')
    .update({
      is_blocked: false,
      blocked_reason: null,
      blocked_at: null
    })
    .eq('id', userId);

  await writeAdminLog({
    adminId: admin.id,
    action: 'user.unban',
    entityType: 'user',
    entityId: userId
  });

  revalidatePath('/users');
}

const reportSchema = z.object({
  reportId: uuid,
  status: z.enum(['reviewing', 'resolved', 'rejected']),
  resolution: z.string().max(800).optional()
});

export async function updateReportAction(formData: FormData) {
  const admin = await requireAdmin();
  const input = reportSchema.parse({
    reportId: formData.get('reportId'),
    status: formData.get('status'),
    resolution: formData.get('resolution') || undefined
  });

  await adminSupabase
    .from('reports')
    .update({
      status: input.status,
      resolution: input.resolution ?? null,
      admin_id: admin.id
    })
    .eq('id', input.reportId);

  await writeAdminLog({
    adminId: admin.id,
    action: 'report.update',
    entityType: 'report',
    entityId: input.reportId,
    details: input
  });

  revalidatePath('/reports');
}

const categorySchema = z.object({
  categoryId: z.string().uuid().optional(),
  parentId: z.string().uuid().optional(),
  taskType: z.enum(['help', 'answer', 'find_item', 'resource']).optional(),
  name: z.string().min(2).max(80),
  slug: z.string().min(2).max(80),
  description: z.string().max(300).optional(),
  sortOrder: z.coerce.number().int().default(0)
});

export async function saveCategoryAction(formData: FormData) {
  const admin = await requireAdmin();
  const input = categorySchema.parse({
    categoryId: formData.get('categoryId') || undefined,
    parentId: formData.get('parentId') || undefined,
    taskType: formData.get('taskType') || undefined,
    name: formData.get('name'),
    slug: formData.get('slug'),
    description: formData.get('description') || undefined,
    sortOrder: formData.get('sortOrder') || 0
  });

  const payload = {
    parent_id: input.parentId ?? null,
    task_type: input.taskType ?? null,
    name: input.name,
    slug: input.slug,
    description: input.description ?? null,
    sort_order: input.sortOrder,
    is_active: true
  };

  if (input.categoryId) {
    await adminSupabase.from('categories').update(payload).eq('id', input.categoryId);
  } else {
    await adminSupabase.from('categories').insert(payload);
  }

  await writeAdminLog({
    adminId: admin.id,
    action: input.categoryId ? 'category.update' : 'category.create',
    entityType: 'category',
    entityId: input.categoryId,
    details: payload
  });

  revalidatePath('/categories');
}

const verificationSchema = z.object({
  userId: uuid,
  status: z.enum(['approved', 'rejected']),
  note: z.string().max(500).optional()
});

export async function updateHelperVerificationAction(formData: FormData) {
  const admin = await requireAdmin();
  const input = verificationSchema.parse({
    userId: formData.get('userId'),
    status: formData.get('status'),
    note: formData.get('note') || undefined
  });

  await adminSupabase
    .from('helper_profiles')
    .update({
      verification_status: input.status,
      verification_note: input.note ?? null
    })
    .eq('user_id', input.userId);

  await writeAdminLog({
    adminId: admin.id,
    action: 'helper.verification.update',
    entityType: 'helper_profile',
    entityId: input.userId,
    details: input
  });

  revalidatePath('/verifications');
  revalidatePath('/helpers');
}
