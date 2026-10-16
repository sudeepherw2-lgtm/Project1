# Triyog High School - Modular Portal & CMS Architecture

Welcome to the newly re-architected **Triyog High School Multi-Portal Management System**. This project is a modern, modular web application combining an Express.js backend with an enterprise-grade vanilla JavaScript frontend. It is 100% operational in both **local offline mode** (via direct `.bat` launchers and `file://` protocol) and **server mode** (Node.js/Express + PostgreSQL).

---

## 🏗️ Clean Modular Architecture

The frontend code has been decoupled from inline `<script>` blocks into a 4-tier modular architecture under `js/`:

```
Project/
├── css/                          # Stylesheets (Bootstrap 5, FontAwesome, Portal Themes)
├── data/
│   └── samples/                  # Excel rosters (iii Unit wise.xlsx, IVUnit wise.xlsx, etc.)
├── fonts/                        # Font assets (MyriadPro, FontAwesome woff/woff2)
├── images/                       # Compressed image assets and brand logos
├── media/                        # Campus tour videos (MP4)
├── js/
│   ├── core/                     # Foundational Architecture Layer
│   │   ├── env.js                # Environment config, storage keys, API endpoint definitions
│   │   ├── seeds.js              # Factory default seed records (events, students, faculty, etc.)
│   │   ├── store.js              # Central State Manager with Pub/Sub & LocalStorage quotas
│   │   ├── utils.js              # Date formatting, Bikram Sambat (BS) converters, HTML escaping
│   │   ├── api.js                # Scalable REST API client with automatic offline fallback
│   │   ├── i18n.js               # Unified English / Nepali translations & icon preservation
│   │   └── app.js                # Shell initializer, live clocks, dynamic branding
│   ├── services/                 # Business Logic Layer
│   │   ├── authService.js        # Session persistence, role detection, access control
│   │   ├── eventService.js       # Event CRUD, validation, media linking
│   │   ├── noticeService.js      # Circulars & PDF routine management
│   │   ├── studentService.js     # Class 1–10 student directory & search
│   │   ├── teacherService.js     # Faculty roster & subject assignments
│   │   ├── casService.js         # Nepal CDC 6-axis grading & Secondary GPA computations
│   │   └── galleryService.js     # Campus photo & banner management
│   ├── components/               # Reusable UI Components
│   │   ├── branding.js           # Dynamic logo & school name synchronizer
│   │   ├── toast.js              # Floating notification toasts
│   │   ├── radarChart.js         # Responsive SVG 6-axis developmental radar generator
│   │   ├── excelImporter.js      # SheetJS dynamic header detection & roster parser
│   │   └── modal.js              # Unified modal controller for campus info & events
│   └── pages/                    # Page Controller Layer
│       ├── indexPage.js          # Public Homepage controller
│       ├── loginPage.js          # Unified Login controller & role switching
│       ├── adminPage.js          # Admin CMS controller (Events, Docs, Ticker, Users, Backup)
│       ├── principalPage.js      # Principal Suite controller (Rosters, Faculty, Accounts)
│       ├── teacherPage.js        # Teacher Panel controller (CDC CAS 1–4 Grid, Homework)
│       └── studentPage.js        # Student/Parent Portal controller (Radar, Badges, Routines)
├── public/
│   └── uploads/                  # Upload destination for PDFs, notices, routines
├── src/                          # Express.js Backend REST API
│   ├── config/db.js              # PostgreSQL pool with in-memory fallback
│   ├── middleware/               # JWT auth & Multer upload middlewares
│   ├── routes/                   # API routes (/api/auth, /api/events, /api/notices, etc.)
│   └── utils/                    # Bikram Sambat calendar utilities
├── index.html                    # Public Marketing Website
├── login.html                    # Unified Portal Login
├── admin.html                    # Executive Admin CMS & Document Center
├── principal.html                # Principal Academic & User Management Suite
├── teacher.html                  # Teacher Grading Workspace (CDC CAS & SEE Tracks)
├── student.html                  # Student & Parent Progress Portal
├── server.js                     # Express.js master coexistence server
├── package.json                  # Dependencies
├── .env                          # Local environment variables
└── .env.example                  # Environment template
```

---

## 🚀 Portals & Launchers

Double-click any `.bat` file to open that portal in your default browser:

| Desktop Launcher | Portal | Role / Purpose |
| :--- | :--- | :--- |
| **`Open_Website.bat`** | Public Homepage (`index.html`) | Campus overview, events, notices, academic wings |
| **`Open_Login_Portal.bat`** | Unified Login (`login.html`) | Role selector & credential verification |
| **`Open_Admin_CMS.bat`** | Admin CMS (`admin.html`) | Events, PDF docs, ticker, gallery, users, backup |
| **`Open_Principal_Dashboard.bat`** | Principal Suite (`principal.html`) | Class 1–10 students, faculty, users, Excel import |
| **`Open_Teacher_Panel.bat`** | Teacher Workspace (`teacher.html`) | CDC CAS 1–4 grading grid, daily homework entry |
| **`Open_Student_Portal.bat`** | Student Portal (`student.html`) | Developmental radar, progress badges, homework |

---

## 🔑 Pre-Configured Test Credentials

| Role | Username | Password | Target Workspace |
| :--- | :--- | :--- | :--- |
| **Principal** | `principal` | `principal` | `principal.html` (Classes 1–10 Suite) |
| **Admin** | `admin` | `admin` | `admin.html` (CMS & File Manager) |
| **Teacher** | `teacher` | `teacher` | `teacher.html` (CAS & Daily Homework) |
| **Student** | `student` | `student` | `student.html` (Student / Parent Progress) |

---

## ⚙️ Core Technical Highlights

1. **State Management (`Triyog.Store`)**:
   - Centralized reactive store with event emitter (`Store.on()`, `Store.emit()`).
   - Quota-safe `localStorage` wrapper that warns on storage exhaustion.
   - Comprehensive system backup export and one-click JSON restore.

2. **Scalable API (`Triyog.Api`)**:
   - Configurable timeout and REST client wrapper.
   - Automatic offline fallback: when backend fetch is unavailable, it reads seamlessly from `Triyog.Store`.

3. **Curriculum Conformance**:
   - **Classes 1–5**: Nepal CDC Continuous Assessment System (CAS) with 6 evaluation axes (Classwork, Project, Discipline, Attendance, Creativity, Unit Tests) rated on a 1–4 scale.
   - **Classes 6–10**: Secondary SEE Terminal evaluation (Homework, Practical, Unit Tests, Attendance) with GPA computation.

4. **Bilingual Support (`Triyog.I18N`)**:
   - Dynamic English and Nepali toggle across all portals.
   - Icon-preserving translation engine ensuring FontAwesome icons remain intact.

5. **White-Label Commercial Theme Engine (`Triyog.Components.Branding`)**:
   - Designed specifically for commercial resale to schools, colleges, and academic institutions across Nepal and abroad.
   - **1-Click Sales Presets**: Instantly switch identities during client demos:
     - 🎓 **Triyog High School** (Navy `#002B49` & Rose Pink `#F272AD` • School)
     - 🏛️ **Kathmandu Model College** (Royal Blue `#0F2B5C` & Amber Gold `#F59E0B` • College)
     - 🌿 **Apex International Academy** (Emerald Green `#064E3B` & Jade `#10B981` • Academy)
     - 🏔️ **Himalayan Public School** (Crimson Maroon `#7F1D1D` & Red `#EF4444` • Higher Sec)
   - **Dynamic Color Injection**: Custom primary and accent colors automatically recolor headers, navbars, buttons, badges, and cards across all 6 portals.
   - **Logo & Contact Customizer**: Upload any local logo (PNG, JPG, SVG, WebP) or specify image paths; custom phone, email, and campus address automatically propagate.
   - **Permanent Customization for Delivery**: Change `Seeds.BRANDING` in `js/core/seeds.js` to hardcode your client's default branding before shipping.

6. **Teacher Panel: Live Search, Nepali Date & WhatsApp Automation**:
   - **Live Student Search**: Quickly filter students by Name or Roll number in real time without refreshing.
   - **Active Nepali Date (वि.सं.) Navigator**: Select and shift dates (e.g. `वि.सं. २०८३ असोज २६`) with previous/next day buttons and quick presets (आज, हिजो, अस्ति).
   - **Dual Workflow Modes**:
     - 📊 **CDC Continuous Assessment (CAS 1–4)**: CDC rubric scoring for units 1–4.
     - ✍️ **Daily Homework Tracker**: Dedicated daily homework checking interface. Mark each student as **Done (✅ सकियो)** or **Not Done (❌ गरेन)** with quick toggle and "Mark All Done" bulk action.
   - **1-Click WhatsApp Parent Notification Automation**:
     - Prominent green **Notify via WhatsApp** button beside each student.
     - When a student is marked "Not Done" (❌), the button pulses to highlight missing work.
     - Clicking opens WhatsApp (`wa.me/977<parent_phone>?text=<encoded_msg>`) with a polite, pre-composed parental message including the school name, date (BS), subject, student name, and specific homework topic.
     - **Broadcast Modal**: 1-click modal listing all students with incomplete homework today, with direct WhatsApp triggers for each and a "Copy All Messages" button.

---

## 🎨 How to Rebrand the Theme for Any Client (Under 60 Seconds)

### Method 1: Instant via Admin CMS (No Coding Required)
1. Launch the Admin CMS via **`Open_Admin_CMS.bat`** (or open `admin.html`).
2. Log in using `admin` / `admin`.
3. Click the **"🎨 School Branding & Theme"** tab from the top navigation.
4. Either click one of the **1-Click Demo Presets** (e.g., *Kathmandu Model College* or *Apex Academy*) OR customize:
   - **Institution Name** (e.g., *Kathmandu Model College*)
   - **Tagline / Motto** (e.g., *Excellence in Higher Education*)
   - **Primary Theme Color** (via native color picker)
   - **Accent Highlight Color** (via native color picker)
   - **Logo Asset** (click "Choose File" to upload the school's logo)
   - **Phone, Email, and Address**
5. Watch the **Live Interactive Header Preview** update in real time.
6. Click **"Save & Apply Theme Everywhere"**.
7. The new school name, colors, and logo are immediately active across all 6 portals!

### Method 2: Permanent Factory Default for Delivery
To package and sell a customized version permanently to a specific institution:
1. Open [`js/core/seeds.js`](file:///c:/Users/user/Documents/Project/js/core/seeds.js).
2. Edit the `BRANDING` block:
   ```javascript
   BRANDING: {
     name: 'Kathmandu Model College',
     tagline: 'Excellence in Academic Leadership & Career Guidance',
     logo: 'images/client-logo.png',
     institutionType: 'college',
     primaryColor: '#0F2B5C',
     accentColor: '#F59E0B',
     phone: '+977-1-4442111',
     email: 'admissions@kmc.edu.np',
     address: 'Balkumari, Lalitpur, Nepal'
   }
   ```
3. Place their logo in `images/client-logo.png`.
4. The system is ready to ship with their branding pre-loaded on first launch!
