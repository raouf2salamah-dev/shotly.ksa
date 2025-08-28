# مكونات واجهة المستخدم

## SmartImage

مكون ذكي لعرض الصور يتكيف مع المنصة التي يعمل عليها التطبيق (ويب، أندرويد، iOS).

### الميزات

- يعرض صورًا من الإنترنت عند تشغيل التطبيق على الويب
- يعرض صورًا من الملفات المحلية على الأجهزة المحمولة وأجهزة الكمبيوتر
- يستخدم صورًا من أصول التطبيق كنسخة احتياطية في حالة فشل تحميل الصور الأخرى
- يدعم ملفات SVG
- يوفر خيارات تخصيص للحجم وطريقة العرض
- يتضمن واجهات للتحميل وعرض الأخطاء

### الاستخدام

```dart
SmartImage(
  webImageUrl: 'https://example.com/image.png',
  assetImagePath: 'assets/images/placeholder.png',
  localFilePath: '/storage/emulated/0/Download/my_image.png',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  loadingWidget: const Center(
    child: CircularProgressIndicator(color: Colors.blue),
  ),
  errorBuilder: (context, error) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.broken_image, size: 50, color: Colors.red),
      const SizedBox(height: 10),
      Text('خطأ في تحميل الصورة: $error', 
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    ],
  ),
)
```

### المعلمات

| المعلمة | النوع | الوصف |
|---------|------|-------|
| `webImageUrl` | `String` | رابط URL للصورة التي سيتم عرضها على الويب |
| `assetImagePath` | `String` | مسار الصورة في أصول التطبيق (يمكن أن تكون SVG) |
| `localFilePath` | `String` | المسار المحلي للصورة على الجهاز |
| `width` | `double?` | عرض الصورة (اختياري) |
| `height` | `double?` | ارتفاع الصورة (اختياري) |
| `fit` | `BoxFit` | كيفية تناسب الصورة مع المساحة المتاحة (الافتراضي: `BoxFit.cover`) |
| `loadingWidget` | `Widget?` | مكون مخصص يظهر أثناء تحميل الصورة (اختياري) |
| `errorBuilder` | `Widget Function(BuildContext, String)?` | دالة لبناء مكون مخصص في حالة حدوث خطأ (اختياري) |