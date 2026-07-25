# 🚀 CachyOS Hyprland (Wayland) Personal Dotfiles & System Rebuilder

مستودع متكامل لإعادة بناء ونقل بيئة العمل المخصصة لتوزيعة **CachyOS** (مبنية على Arch Linux مع بيئة عرض Wayland ومحرّك Hyprland) بنسبة 100%، بما يشمل الاختصارات (Keybindings)، الثيمات، الخلفيات، سكريبتات التحكم، وإعدادات التطبيقات.

---

## ⚠️ تنبيه هام (Virtual Machine Test Recommendation)

> [!RECOMMENDATION]
> **يُوصى بشدة بتجربة هذا السكريبت على بيئة افتراضية (Virtual Machine - VM) جديدة وتوزيعة CachyOS ناعمة قبل تشغيله على جهازك الرئيسي كبيئة إنتاج.**

---

## ⚡ التثبيت السريع (One-Liner Installation)

يمكنك تثبيت واستعادة نظامك بالكامل على أي جهاز CachyOS جديد أو نظام Arch مغسول بأمر واحد عبر الطرفية:

```bash
curl -sSL https://raw.githubusercontent.com/omarahmed321/new-config-cachyos/main/install.sh | bash
```

أو يمكنك استنساخ الريبو وتشغيله محلياً:

```bash
git clone https://github.com/omarahmed321/new-config-cachyos.git
cd new-config-cachyos
chmod +x install.sh sync.sh
./install.sh
```

---

## 📂 هيكلية المستودع (Repository Structure)

```text
.
├── install.sh                # سكريبت التثبيت والاستعادة الرئيسي (Idempotent & Modular)
├── sync.sh                   # سكريبت المزامنة وجلب التحديثات الجديدة من جهازك للريبو
├── README.md                 # دليل الاستخدام والتوضيحات
├── .gitignore                # استبعاد مفاتيح SSH وGPG والتوكنز والبيانات الحساسة
├── packages/
│   ├── pacman.txt            # قائمة الحزم الرسمية (Pacman)
│   └── aur.txt               # قائمة حزم AUR
├── configs/                  # إعدادات التطبيقات (~/.config)
│   ├── hypr/                 # إعدادات Hyprland و Keybindings و Monitos و Nightlight
│   ├── waybar/               # شريط المهام
│   ├── rofi/                 # مشغل التطبيقات
│   ├── dunst/                # الإشعارات
│   ├── kitty/ & alacritty/   # الطرفية
│   ├── gtk-3.0/ & gtk-4.0/   # ثيمات GTK
│   ├── qt5ct/ & qt6ct/       # ثيمات Qt
│   └── ...                   # كافة التكوينات المرفقة
├── dotfiles/                 # ملفات الهوم (.zshrc, .bashrc, .gitconfig)
├── keybinds/                 # اختصارات لوحة المفاتيح المخصصة كاملة
├── scripts/                  # سكريبتات النظام المخصصة (~/.local/share/bin)
├── vscode/                   # إعدادات وإضافات VSCode
├── wallpapers/               # الخلفيات المخصصة
├── fonts/                    # الخطوط المخصصة
├── services/                 # قائمة خدمات systemd user المفعّلة
└── tools/                    # أدوات التحكم بعد التثبيت واختبار VM (GUI/CLI)
    ├── create_test_vm.sh    # سكريبت إنشاء وتشغيل VM افتراضية لتوزيعة CachyOS
    ├── nightlight-config.py  # أداة ضبط الإضاءة الليلية
    ├── display-config.py     # أداة ضبط الشاشات والماوس
    └── monitor-alignment.py  # أداة محاذاة وترتيب الشاشات المتعددة
```

---

## 🖥️ أدوات التحكم الرسومية بعد التثبيت (GUI Post-Install Tools)

تحتوي مجلد `tools/` على 3 أدوات بسيطة مكتوبة بـ Python و GTK3 تعمل مباشرة على Wayland:

### 1. الإضاءة الليلية (`nightlight-config.py`)
تسمح لك بتعديل درجة حرارة اللون (Temperature)، السطوع (Gamma)، وتفعيل/تعطيل hyprsunset مباشرة وحفظها بصفة دائمة:
```bash
python3 tools/nightlight-config.py
```

### 2. إعدادات الشاشة والماوس (`display-config.py`)
تسمح بتعديل الدقة (Resolution)، معدل التحديث (Refresh Rate)، مقياس العرض (Scale)، وحساسية الماوس (Mouse Sensitivity):
```bash
python3 tools/display-config.py
```

### 3. محاذاة الشاشات المتعددة (`monitor-alignment.py`)
تتيح لك محاذاة وتحديد مواقع الشاشات المتعددة (X/Y Offsets) لضمان حركة سلسة لمؤشر الماوس بدون قفزات عشوائية بين الشاشات:
```bash
python3 tools/monitor-alignment.py
```

---

## 🎮 التحكم لكروت الشاشة (Hybrid GPU Switching)

السكريبت يكتشف كروت الشاشة تلقائياً. إذا كان جهازك يحتوي على كرت مدمج (Intel/AMD) + كرت منفصل (NVIDIA):
- يتم تثبيت التعريفات وأداة `envycontrol`.
- يمكنك التبديل بين الأوضاع في أي وقت بأوامر:
  - **الوضع الهجين (Hybrid):** `sudo envycontrol -s hybrid`
  - **وضع الكرت المدمج (Integrated):** `sudo envycontrol -s integrated`
  - **وضع النفييديا فقط (NVIDIA):** `sudo envycontrol -s nvidia`
*(ثم إعادة تشغيل الجهاز)*.

> **ملاحظة لأجهزة أبل/أبوس (ASUS Laptops):** تتوفر أداة `supergfxctl` أيضاً كبديل مخصص.

---

## 🔄 مزامنة التحديثات الجديدة (`sync.sh`)

في أي وقت تقوم بتعديل إعداداتك أو إضافة keybinds جديدة وتريد رفعها للمستودع:
```bash
./sync.sh
```
سيقوم السكريبت بتفحص النظام، جلب كافة التعديلات، تنقية المسارات المطلقة وتنسيقها تلقائياً.

---

## 📌 خطوات يدوية بعد التثبيت

1. إعادة تشغيل الجهاز (Reboot) أو تسجيل الخروج لضمان تحميل كل الخدمات وجلسة Hyprland.
2. استخدام أدوات GUI في `tools/` لتعديل أي إعدادات تخص الشاشات والإضاءة الليلية حسب رغبتك.
