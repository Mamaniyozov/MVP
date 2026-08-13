---
name: ux-ui-pro-max
description: Pro Max 3D Panel UI (Neumorphism) generator for TailwindCSS and Next.js, featuring white/light backgrounds and extruded glass/3D surfaces.
---

# UX/UI Pro Max 3D Panel Skill

Ushbu skill agentlar frontend va UI kodlarini yozayotganda, ularga eng zamonaviy "Pro Max" Neumorphism (3D panel) estetikasini qo'llashda yordam beradi.

## Core Aesthetic Rules
1. **Background**: Har doim oq yoki och kulrang (`#F0F3F6` kabi) fon ishlating. Sof oq rang (`#FFFFFF`) ni panellar uchun qoldiring.
2. **3D Panels (Neumorphism)**:
   - Panellar foni bilan bir xil rangda (yoki sal oqroq) bo'lishi kerak.
   - Tashqariga chiqqan effekt (Outset) uchun soya: `9px 9px 16px rgb(163,177,198,0.6), -9px -9px 16px rgba(255,255,255, 0.6)`.
   - Ichkariga botgan effekt (Inset, masalan inputlar uchun) soya: `inset 5px 5px 10px rgba(163,177,198, 0.5), inset -5px -5px 10px rgba(255,255,255, 0.8)`.
3. **Border Radius**: Elementlar yumshoq va silliq ko'rinishi uchun `rounded-2xl` (`16px`) yoki `rounded-3xl` (`24px`) ishlating.
4. **Dark Mode**: Dark mode holatida neumorphism o'rniga, Glassmorphism (yarim shaffof orqa fon, xira border) effektiga o'ting, chunki qora fonda oddiy 3D panellar xunuk ko'rinishi mumkin.

## Qachon qo'llash kerak?
- Yangi kartochka (Card), panel, yoki input komponentlarini yaratganda.
- "3D", "Pro Max", "Chiroyli", "Yangi UI" degan talablar bo'lganda ushbu qoidalarni Tailwind klaslari orqali (`.panel`, `.panel-inset`) silliq qo'llang.
