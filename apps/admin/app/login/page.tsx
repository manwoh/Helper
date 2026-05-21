import { LoginForm } from './login-form';

export default async function LoginPage({
  searchParams
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const params = await searchParams;
  const error = params.error === 'admin' ? '当前账号不是管理员。' : undefined;

  return (
    <main className="login-page">
      <LoginForm error={error} />
    </main>
  );
}
