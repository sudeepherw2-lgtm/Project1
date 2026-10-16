-- ========================================================
-- PEGASUS ENGLISH SCHOOL - PORTAL & CMS DATABASE SCHEMA (PostgreSQL)
-- Supabase-Ready & Hardened with Row-Level Security (RLS)
-- ========================================================

-- Drop existing tables if re-initializing
DROP TABLE IF EXISTS student_results CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS cas_evaluations CASCADE;
DROP TABLE IF EXISTS homework CASCADE;
DROP TABLE IF EXISTS uploads CASCADE;
DROP TABLE IF EXISTS nepali_holidays CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS content_category CASCADE;

-- 1. User Roles & Table
CREATE TYPE user_role AS ENUM ('principal', 'admin', 'teacher', 'student', 'parent');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role user_role NOT NULL,
    grade_level INT,             -- For primary students and grade teachers (1-10)
    section VARCHAR(5),          -- e.g. 'A', 'B'
    roll_no INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. File Uploads & CMS Content (Notices, Routines, Gallery)
CREATE TYPE content_category AS ENUM ('notice', 'routine', 'slider', 'publication');

CREATE TABLE uploads (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category content_category NOT NULL DEFAULT 'notice',
    file_path VARCHAR(500) NOT NULL,          -- Relative local path or Supabase storage URL
    original_filename VARCHAR(255) NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    file_size INT NOT NULL,
    published_date DATE NOT NULL DEFAULT CURRENT_DATE,
    nepali_date VARCHAR(25),                  -- e.g. "२०८३ असोज २६"
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. School Events & Academic Calendar
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'academic',
    year VARCHAR(10) NOT NULL,
    month VARCHAR(10) NOT NULL,
    day VARCHAR(10) NOT NULL,
    date_ad DATE NOT NULL,
    date_bs VARCHAR(30) NOT NULL,
    time VARCHAR(50),
    venue VARCHAR(150) DEFAULT 'Pegasus Campus',
    status VARCHAR(30) DEFAULT 'upcoming',
    grades VARCHAR(100) DEFAULT 'All Classes',
    description TEXT,
    link VARCHAR(255) DEFAULT '#',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Nepali National & School Holidays Table
CREATE TABLE nepali_holidays (
    id SERIAL PRIMARY KEY,
    holiday_name VARCHAR(150) NOT NULL,
    holiday_date_ad DATE NOT NULL UNIQUE,
    holiday_date_bs VARCHAR(25) NOT NULL,
    description TEXT
);

-- 5. Nepal CDC Continuous Assessment System (CAS) for Grades 1–5
-- Rubric Scale (1 to 4):
-- 4 = धेरै राम्रो (Advanced / 80-100%)
-- 3 = राम्रो (Proficient / 60-79%)
-- 2 = सामान्य (Developing / 40-59%)
-- 1 = प्रारम्भिक (Beginning / <40%)
CREATE TABLE cas_evaluations (
    id SERIAL PRIMARY KEY,
    student_id INT REFERENCES users(id) ON DELETE CASCADE,
    teacher_id INT REFERENCES users(id) ON DELETE SET NULL,
    grade INT NOT NULL CHECK (grade BETWEEN 1 AND 10),
    subject VARCHAR(60) NOT NULL,
    week_number INT NOT NULL CHECK (week_number BETWEEN 1 AND 52),
    academic_year VARCHAR(10) NOT NULL DEFAULT '2083',
    evaluation_date_ad DATE NOT NULL,
    evaluation_date_bs VARCHAR(25) NOT NULL,
    
    -- 5 CDC Assessment Learning Criteria
    criterion_participation SMALLINT NOT NULL CHECK (criterion_participation BETWEEN 1 AND 4),
    criterion_practical SMALLINT NOT NULL CHECK (criterion_practical BETWEEN 1 AND 4),
    criterion_discipline SMALLINT NOT NULL CHECK (criterion_discipline BETWEEN 1 AND 4),
    criterion_neatness SMALLINT NOT NULL CHECK (criterion_neatness BETWEEN 1 AND 4),
    criterion_creativity SMALLINT NOT NULL CHECK (criterion_creativity BETWEEN 1 AND 4),
    
    teacher_feedback TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_weekly_student_eval UNIQUE (student_id, subject, academic_year, week_number)
);

-- 6. Daily Homework Tracker
CREATE TABLE homework (
    id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES users(id) ON DELETE CASCADE,
    grade INT NOT NULL CHECK (grade BETWEEN 1 AND 10),
    section VARCHAR(5) DEFAULT 'All',
    subject VARCHAR(60) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    due_date_bs VARCHAR(25) NOT NULL,
    due_date_ad DATE,
    attachment_path VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Terminal Exam Results & Marksheets (Imported from Excel / Principal Suite)
CREATE TABLE student_results (
    id SERIAL PRIMARY KEY,
    symbol_no VARCHAR(50) UNIQUE NOT NULL,
    student_name VARCHAR(150) NOT NULL,
    class_id VARCHAR(10) NOT NULL,
    section VARCHAR(10) DEFAULT 'A',
    roll_no INT,
    term VARCHAR(50) DEFAULT 'First Terminal Examination 2083',
    subjects JSONB NOT NULL DEFAULT '[]'::jsonb,
    gpa NUMERIC(3,2) NOT NULL DEFAULT 0.00,
    overall_grade VARCHAR(5) NOT NULL DEFAULT 'NG',
    total_obtained NUMERIC(6,2) DEFAULT 0,
    total_full_marks NUMERIC(6,2) DEFAULT 0,
    percentage NUMERIC(5,2) DEFAULT 0,
    attendance VARCHAR(30) DEFAULT '98%',
    remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================
-- ROW-LEVEL SECURITY (RLS) POLICIES FOR SUPABASE
-- Ensures tables are NOT world-writable even if PostgREST API is exposed
-- ========================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE nepali_holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE cas_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_results ENABLE ROW LEVEL SECURITY;

-- 1. Public Read Policies (Safe for anon visitor browsing)
CREATE POLICY "Public can view active uploads" ON uploads FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Public can view events" ON events FOR SELECT USING (TRUE);
CREATE POLICY "Public can view nepali holidays" ON nepali_holidays FOR SELECT USING (TRUE);
CREATE POLICY "Public can view homework" ON homework FOR SELECT USING (TRUE);
CREATE POLICY "Public can search student terminal results" ON student_results FOR SELECT USING (TRUE);

-- 2. Restrict Sensitive Tables from Direct Anon Access
-- Backend Express server connects via postgres connection string (service_role), bypassing RLS safely.
-- Direct PostgREST / anon clients CANNOT read password hashes or tamper with records.
CREATE POLICY "Deny anon access to users" ON users FOR ALL USING (FALSE);
CREATE POLICY "Deny anon modifications to uploads" ON uploads FOR INSERT WITH CHECK (FALSE);
CREATE POLICY "Deny anon modifications to events" ON events FOR INSERT WITH CHECK (FALSE);
CREATE POLICY "Deny anon modifications to cas" ON cas_evaluations FOR ALL USING (FALSE);
CREATE POLICY "Deny anon modifications to student_results" ON student_results FOR INSERT WITH CHECK (FALSE);

-- ========================================================
-- INITIAL SEED DATA
-- Default Passwords (bcrypt hashes for role-based system accounts)
-- Admin: admin | Principal: principal | Teacher: teacher | Student: student | Parent: parent
-- ========================================================

INSERT INTO users (username, email, password_hash, full_name, role, grade_level, section, roll_no)
VALUES 
('admin', 'admin@pegasus.edu.np', '$2a$10$H8f9xjuSZV.nlo8xy5CYxuThzkh3qwdoCtor.VbmM2omaYIcJvoAa', 'System Administrator', 'admin', NULL, NULL, NULL),
('principal', 'principal@pegasus.edu.np', '$2a$10$Ggw/H2MG3rFqb4Jt7D4s/e7qV0r.CEhwKzQ7d.9CyiZyKID3gtS56', 'Principal Office', 'principal', NULL, NULL, NULL),
('teacher', 'teacher@pegasus.edu.np', '$2a$10$Bf8DVZMA7U9YriFKkN81QuwjlYUo2Nvl0D69v5UM476PvgnbBzoFm', 'Aarav Shrestha (Grade 3 Teacher)', 'teacher', 3, 'A', NULL),
('student', 'student@pegasus.edu.np', '$2a$10$iDLzcafNjoEYKQ/lU5Bi6ObTSkOaruGlP4tKtEow7crihZJOkAeR.', 'Rohan Adhikari', 'student', 3, 'A', 12),
('parent', 'parent@pegasus.edu.np', '$2a$10$HGQepSt90N2Tb7EdqHZy/.RFbI.qmY1LCbWpPmBPrN7hAb/BchISK', 'Mr. & Mrs. Adhikari (Parent of Rohan)', 'parent', 3, 'A', 12);

-- Pre-seed Key Nepali Holidays
INSERT INTO nepali_holidays (holiday_name, holiday_date_ad, holiday_date_bs, description)
VALUES 
('दशैं टिका (Dashain Tika)', '2026-10-20', '२०८३-०७-०४', 'National Holiday - Vijaya Dashami'),
('दीपावली / तिहार (Tihar Holiday)', '2026-11-08', '२०८३-०७-२३', 'National Holiday - Laxmi Puja'),
('माघे सङ्क्रान्ति (Maghe Sankranti)', '2027-01-15', '२०८३-१०-०१', 'National Holiday'),
('प्रजातन्त्र दिवस (Democracy Day)', '2027-02-19', '२०८३-११-०७', 'National Holiday'),
('महाशिवरात्रि (Maha Shivaratri)', '2027-03-07', '२०८३-११-२३', 'National Holiday'),
('होली (Fagu Purnima)', '2027-03-22', '२०८३-१२-०८', 'National Festival of Colors'),
('नयाँ वर्ष (Nepali New Year 2084)', '2027-04-14', '२०८४-०१-०१', 'Bikram Sambat New Year');

-- Sample Initial Notices
INSERT INTO uploads (title, category, file_path, original_filename, file_type, file_size, published_date, nepali_date, created_by)
VALUES 
('Admission Open for Academic Session 2083/84 (Pre-School to Grade X)', 'notice', '/uploads/notices/sample_admission_notice.pdf', 'sample_admission_notice.pdf', 'application/pdf', 245000, '2026-10-10', '२०८३ असोज २४', 1),
('First Term Examination Routine & Syllabus (Grades 1 to 10)', 'routine', '/uploads/routines/term1_routine_2083.pdf', 'term1_routine_2083.pdf', 'application/pdf', 189000, '2026-10-05', '२०८३ असोज १९', 1),
('Notice Regarding Dashain & Tihar Vacation Schedule', 'notice', '/uploads/notices/dashain_vacation_notice.pdf', 'dashain_vacation_notice.pdf', 'application/pdf', 312000, '2026-10-02', '२०८३ असोज १६', 1);

-- Sample Initial Events
INSERT INTO events (title, category, year, month, day, date_ad, date_bs, time, venue, status, grades, description)
VALUES
('Inter-House Science Exhibition 2083', 'academic', '2026', 'Oct', '25', '2026-10-25', '२०८३ कार्तिक ०९', '10:00 AM - 03:30 PM', 'Pegasus Senior Block', 'upcoming', 'Grades IV - X', 'Showcasing student STEM prototypes, robotics demonstrations, and applied chemistry lab displays.'),
('First Terminal Examination 2083', 'academic', '2026', 'Nov', '02', '2026-11-02', '२०८३ कार्तिक १७', '08:00 AM - 11:30 AM', 'Examination Halls A & B', 'upcoming', 'Grades I - X', 'CDC curriculum-based evaluation covering all core academic subjects and continuous assessment criteria.'),
('Dashain Cultural Program & Deusi Bhailo', 'cultural', '2026', 'Oct', '18', '2026-10-18', '२०८३ असोज २६', '11:00 AM - 02:00 PM', 'Main Assembly Auditorium', 'completed', 'All Classes', 'Annual pre-vacation cultural festivities with traditional folk dances, drama, and blessing ceremonies.');

-- Sample CAS Evaluations
INSERT INTO cas_evaluations (student_id, teacher_id, grade, subject, week_number, academic_year, evaluation_date_ad, evaluation_date_bs, criterion_participation, criterion_practical, criterion_discipline, criterion_neatness, criterion_creativity, teacher_feedback)
VALUES 
(4, 3, 3, 'English', 24, '2083', '2026-10-08', '२०८३ असोज २२', 4, 3, 4, 3, 4, 'Excellent creative storytelling and active participation in group reading.'),
(4, 3, 3, 'Mathematics', 24, '2083', '2026-10-08', '२०८३ असोज २२', 3, 4, 4, 3, 3, 'Shows great interest in geometric shapes practical model making.'),
(4, 3, 3, 'Science', 24, '2083', '2026-10-08', '२०८३ असोज २२', 3, 4, 4, 4, 4, 'Very neat project notebook and active leaf classification submission.');

-- Sample Daily Homework
INSERT INTO homework (teacher_id, grade, section, subject, title, description, due_date_bs, due_date_ad)
VALUES 
(3, 3, 'A', 'Science', 'Leaf Collection and Classification Project', 'Collect 5 different fallen leaves from your garden. Paste them into your scrapbook with labels: shape, size, and margin.', '२०८३ असोज २८', '2026-10-14'),
(3, 3, 'A', 'Nepali', 'हाम्रो चाडपर्व अनुच्छेद लेखन', 'दशैं वा तिहारका बारेमा ५ वाक्यहरू सफा अक्षरमा आफ्नो कापीमा लेख्नुहोस्।', '२०८३ असोज २९', '2026-10-15');

-- Sample Student Results
INSERT INTO student_results (symbol_no, student_name, class_id, section, roll_no, term, subjects, gpa, overall_grade, total_obtained, total_full_marks, percentage, remarks)
VALUES
('PES-2083-0401', 'Aarav Sharma', 'IV', 'A', 1, 'First Terminal Examination 2083', 
 '[{"name":"English","th":36,"pr":10,"total":46,"grade":"A","gp":3.6},{"name":"Nepali","th":34,"pr":10,"total":44,"grade":"A","gp":3.6},{"name":"Mathematics","th":38,"pr":10,"total":48,"grade":"A+","gp":4.0},{"name":"Science","th":35,"pr":10,"total":45,"grade":"A","gp":3.6},{"name":"Social Studies","th":33,"pr":10,"total":43,"grade":"A","gp":3.6},{"name":"Computer Science","th":37,"pr":10,"total":47,"grade":"A+","gp":4.0}]'::jsonb,
 3.73, 'A', 273.00, 300.00, 91.00, 'Outstanding academic performance across all disciplines.'),
('PES-2083-0402', 'Bipana Rai', 'IV', 'A', 2, 'First Terminal Examination 2083',
 '[{"name":"English","th":35,"pr":10,"total":45,"grade":"A","gp":3.6},{"name":"Nepali","th":36,"pr":10,"total":46,"grade":"A","gp":3.6},{"name":"Mathematics","th":37,"pr":10,"total":47,"grade":"A+","gp":4.0},{"name":"Science","th":34,"pr":10,"total":44,"grade":"A","gp":3.6},{"name":"Social Studies","th":35,"pr":10,"total":45,"grade":"A","gp":3.6},{"name":"Computer Science","th":36,"pr":10,"total":46,"grade":"A","gp":3.6}]'::jsonb,
 3.67, 'A', 269.00, 300.00, 89.67, 'Consistent focus and diligent coursework throughout the term.');
