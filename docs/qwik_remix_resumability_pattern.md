# Qwik & Remix Full-Stack Resumability Architecture Pattern

Ushbu hujjat **Qwik** (Resumability, $ lazy boundaries, $O(1)$ loading) va **Remix** (Web Standards, Progressive Enhancement, Server Loader/Action, Optimistic UI) arxitektura patternlarini birlashtirgan full-stack web loyihalash va offline-sync qo'llanmasini taqdim etadi.

---

## 1. Qwik Core Principles (Resumability & $ Boundaries)

### Resumability (Gidratatsiyasiz yuklanish)
- **Problem**: An'anaviy SPA (React/Vue) va SSR freymvorklari sahifa yuklangach butun VDOM daraxtini qayta gidratatsiya (Hydration) qiladi va ko'p javaskript kodini yuklaydi.
- **Qwik Solution**: Qwik sahifa holatini (State) HTML markup ichiga serializatsiya qilib beradi. Brauzerda gidratatsiya umuman bajarilmaydi — foydalanuvchi faqat biror tugmani bosgandagina shunga mos funksiya javaskripti yuklanadi ($O(1)$ startup).

### Lazy Loading Boundaries (`$`)
- `component$`: Resumable komponent chegarasi.
- `$`: Qwik Optimizer uchun javaskriptni alohida bo'laklarga (Code splitting) bo'lish belgisi.
- `useSignal`: Primativ qiymatlar va reaktiv holat saqlagich.
- `useStore`: Chuqur obyektlar va massivlar uchun serializatsiyalanuvchi reaktiv saqlagich.
- `routeLoader$`: Server tomonida ma'lumotlarni parallel ravishda tayyorlab berish (`GET`).
- `routeAction$`: Server mutation va progresiv formani qayta ishlash (`POST`/`PUT`).

---

## 2. Remix Web Standards & Progressive Enhancement

### Server-Client Bridge
- **Standard Forms (`<Form>`)**: Formani standart HTML `action` va `method` atributlari bilan topshiradi. Javaskript o'chirilgan holatda ham forma ishlaydi (Progressive Enhancement).
- **Optimistic UI**: Mutatsiya natijasi serverdan qaytishini kutmasdan darhol UI'da yangilanishni ko'rsatish (`useNavigation` yoki Qwik `useAction`).
- **Automatic Loader Revalidation**: Har qanday `action` muvaffaqiyatli yakunlangach, unga bog'liq barcha `loader` ma'lumotlari avtomatik ravishda qayta yuklanadi.

---

## 3. Integrated Full-Stack Architecture Strategy

```
[Client (Qwik UI / Flutter)] 
       │ 
       ├── (Offline) ──> [Hive / Local Storage Cache]
       │
       └── (Online)  ──> [Qwik City / Remix Loader & Action] ──> [Django REST Backend API]
```

### Pattern Best Practices:
1. **Zero-Hydration Eager Boundary**: Og'ir `useVisibleTask$` o'rniga barcha dastlabki ma'lumotlarni `routeLoader$` yoki server `loader`ida tayyorlash.
2. **Serializable State**: `useStore` va Hive keshida saqlanadigan obyektlarni faqat serializatsiyalanuvchi (JSON-safe) ko'rinishda ushlash.
3. **Optimistic Mutation Queue**: Server yettib bo'lmas holatda so'rovni lokal navbatga yozish va aloqa tiklangach `routeAction$` orqali backendga yuborish.
