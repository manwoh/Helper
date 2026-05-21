# 找帮手 Flutter App

## 运行

```powershell
flutter pub get
flutter run `
  --dart-define=SUPABASE_URL=https://xzjyinsvpxgzdxbuluct.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

如果当前目录还没有平台工程文件，可以先执行：

```powershell
flutter create .
```

然后保留 `lib/` 和 `pubspec.yaml` 中的业务代码。
