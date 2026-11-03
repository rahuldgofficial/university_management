-- #############################################################################
-- TIER-1 UNIVERSITY ENTERPRISE DATABASE ARCHITECTURE (PRODUCTION RELEASE v2.0)
-- 
-- Designed for Large-Scale Academic Institutions (e.g. Stanford / MIT Scale)
-- Engine: InnoDB | Charset: utf8mb4 | Collation: utf8mb4_unicode_520_ci
-- Normalized to 3NF/BCNF | ACID Compliant | Complete Foreign Key Topology
-- #############################################################################

-- #############################################################################
-- TIER-1 UNIVERSITY ENTERPRISE DATABASE ARCHITECTURE
-- Production DDL: Strict Topological Ordering, InnoDB, utf8mb4, Full Relational Integrity
-- Compatible with MySQL 8.0+ / MariaDB 10.6+ / Amazon Aurora MySQL
-- #############################################################################

SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- 1. CAMPUSES & PHYSICAL FACILITIES (Pre-requisite for rooms & schedules)
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS campuses;
CREATE TABLE campuses (
  id              SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(100)       NOT NULL UNIQUE,
  code            VARCHAR(10)        NOT NULL UNIQUE,
  location        VARCHAR(255)       NULL,
  timezone        VARCHAR(50)        NOT NULL DEFAULT 'America/Los_Angeles',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Multi-campus geographical locations and timezone anchors';

DROP TABLE IF EXISTS buildings;
CREATE TABLE buildings (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  campus_id       SMALLINT UNSIGNED  NOT NULL,
  code            VARCHAR(20)        NOT NULL,
  name            VARCHAR(100)       NOT NULL,
  total_floors    TINYINT UNSIGNED   NOT NULL DEFAULT 1,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  UNIQUE KEY uq_building_campus     (campus_id, code),
  FOREIGN KEY (campus_id) REFERENCES campuses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='University physical buildings and complex infrastructures';

DROP TABLE IF EXISTS rooms;
CREATE TABLE rooms (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  building_id     BIGINT UNSIGNED    NOT NULL,
  room_no         VARCHAR(20)        NOT NULL,
  room_type       ENUM('lecture_hall','lab','seminar','office','auditorium','study') NOT NULL DEFAULT 'lecture_hall',
  capacity        SMALLINT UNSIGNED  NOT NULL,
  has_projector   BOOLEAN            NOT NULL DEFAULT 1,
  is_accessible   BOOLEAN            NOT NULL DEFAULT 1 COMMENT 'ADA Compliant accessibility flag',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_room_building        (building_id, room_no),
  FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Classrooms, laboratory spaces, and faculty offices';

-- -----------------------------------------------------------------------------
-- 2. ACADEMIC GOVERNANCE & DEGREE PROGRAMS
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS departments;
CREATE TABLE departments (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  campus_id       SMALLINT UNSIGNED  NOT NULL,
  code            VARCHAR(10)        NOT NULL,
  name            VARCHAR(100)       NOT NULL,
  budget_code     VARCHAR(30)        NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  UNIQUE KEY uq_dept_code            (campus_id, code),
  FOREIGN KEY (campus_id) REFERENCES campuses(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Academic and administrative departments within colleges';

DROP TABLE IF EXISTS degree_programs;
CREATE TABLE degree_programs (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  department_id   BIGINT UNSIGNED    NOT NULL,
  code            VARCHAR(20)        NOT NULL UNIQUE,
  name            VARCHAR(150)       NOT NULL,
  level           ENUM('BSc','BA','MSc','PhD','Certificate','MD','JD') NOT NULL,
  duration_months TINYINT UNSIGNED   NOT NULL,
  total_credits   DECIMAL(5,1)       NOT NULL DEFAULT 120.0,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Degree offerings across undergraduate, graduate, and professional schools';

DROP TABLE IF EXISTS degree_requirements;
CREATE TABLE degree_requirements (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  program_id      BIGINT UNSIGNED    NOT NULL,
  requirement     VARCHAR(255)       NOT NULL,
  min_credits     DECIMAL(4,1)       NOT NULL DEFAULT 0.0,
  min_gpa         DECIMAL(3,2)       NOT NULL DEFAULT 2.00,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (program_id) REFERENCES degree_programs(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Graduation criteria and minimum curricular standards';

DROP TABLE IF EXISTS terms;
CREATE TABLE terms (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  code            VARCHAR(20)        NOT NULL UNIQUE COMMENT 'e.g. 2026-AUTUMN, 2027-SPRING',
  name            VARCHAR(50)        NOT NULL,
  term_type       ENUM('quarter','semester','summer') NOT NULL DEFAULT 'quarter',
  academic_year   YEAR               NOT NULL,
  start_date      DATE               NOT NULL,
  end_date        DATE               NOT NULL,
  add_drop_date   DATE               NOT NULL,
  grade_due_date  DATE               NOT NULL,
  is_active       BOOLEAN            NOT NULL DEFAULT 0,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (end_date > start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Academic calendar intervals and enrollment windows';

-- -----------------------------------------------------------------------------
-- 3. CORE IDENTITY & UNIFIED PERSON REGISTRY
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  campus_id       SMALLINT UNSIGNED  NULL,
  sunet_id        VARCHAR(15)        UNIQUE COMMENT 'Stanford/Enterprise Single Sign-On ID',
  name            VARCHAR(100)       NOT NULL,
  email           VARCHAR(255)       NOT NULL UNIQUE,
  password        VARCHAR(255)       NOT NULL,
  phone           VARCHAR(25)        NULL,
  is_active       BOOLEAN            NOT NULL DEFAULT 1,
  ferpa_suppress  BOOLEAN            NOT NULL DEFAULT 0 COMMENT 'FERPA privacy directory information block',
  last_login_at   DATETIME           NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  FOREIGN KEY (campus_id) REFERENCES campuses(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Central authentication and user entity table';

DROP TABLE IF EXISTS roles;
CREATE TABLE roles (
  id              TINYINT UNSIGNED   AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(50)        NOT NULL UNIQUE,
  description     VARCHAR(255)       NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='System role definitions for RBAC';

DROP TABLE IF EXISTS user_roles;
CREATE TABLE user_roles (
  user_id         BIGINT UNSIGNED    NOT NULL,
  role_id         TINYINT UNSIGNED   NOT NULL,
  created_by      BIGINT UNSIGNED    NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Many-to-many user role assignment matrix';

DROP TABLE IF EXISTS students;
CREATE TABLE students (
  id               BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id          BIGINT UNSIGNED    NOT NULL UNIQUE,
  student_number   VARCHAR(20)        NOT NULL UNIQUE,
  program_id       BIGINT UNSIGNED    NULL,
  catalog_year     YEAR               NOT NULL DEFAULT 2026,
  enrollment_date  DATE               NOT NULL,
  graduation_date  DATE               NULL,
  status           ENUM('active','on_leave','graduated','withdrawn','suspended') NOT NULL DEFAULT 'active',
  created_at       TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at       TIMESTAMP          NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (program_id) REFERENCES degree_programs(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Enrolled student profile registry';

DROP TABLE IF EXISTS student_programs;
CREATE TABLE student_programs (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  program_id      BIGINT UNSIGNED    NOT NULL,
  program_type    ENUM('major','double_major','minor','coterminal','certificate') NOT NULL DEFAULT 'major',
  declared_at     DATE               NOT NULL,
  status          ENUM('active','completed','dropped') NOT NULL DEFAULT 'active',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_student_program_type (student_id, program_id, program_type),
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (program_id) REFERENCES degree_programs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Multi-major, double-degree, and minor declarations for students';

DROP TABLE IF EXISTS faculty;
CREATE TABLE faculty (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED    NOT NULL UNIQUE,
  department_id   BIGINT UNSIGNED    NOT NULL,
  office_room_id  BIGINT UNSIGNED    NULL,
  hire_date       DATE               NOT NULL,
  rank            ENUM('Assistant','Associate','Full','Emeritus','Adjunct','Lecturer') NOT NULL,
  tenured         BOOLEAN            NOT NULL DEFAULT 0,
  tenure_date     DATE               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
  FOREIGN KEY (office_room_id) REFERENCES rooms(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Academic faculty, researchers, and professorial appointments';

DROP TABLE IF EXISTS staff;
CREATE TABLE staff (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED    NOT NULL UNIQUE,
  department_id   BIGINT UNSIGNED    NOT NULL,
  office_room_id  BIGINT UNSIGNED    NULL,
  hire_date       DATE               NOT NULL,
  position        VARCHAR(100)       NOT NULL,
  supervisor_id   BIGINT UNSIGNED    NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
  FOREIGN KEY (office_room_id) REFERENCES rooms(id) ON DELETE SET NULL,
  FOREIGN KEY (supervisor_id) REFERENCES staff(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Administrative, laboratory, and operations staff';

-- -----------------------------------------------------------------------------
-- 4. COURSE CATALOG & CURRICULAR REQUIREMENTS
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS courses;
CREATE TABLE courses (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  department_id   BIGINT UNSIGNED    NOT NULL,
  code            VARCHAR(15)        NOT NULL,
  title           VARCHAR(150)       NOT NULL,
  description     TEXT               NULL,
  credits         DECIMAL(3,1)       NOT NULL DEFAULT 3.0,
  is_repeatable   BOOLEAN            NOT NULL DEFAULT 0,
  grading_basis   ENUM('letter','pass_fail','audit','both') NOT NULL DEFAULT 'both',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  UNIQUE KEY uq_course_code          (department_id, code),
  FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
  CHECK (credits >= 0.0 AND credits <= 30.0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Master curriculum catalog courses';

DROP TABLE IF EXISTS course_programs;
CREATE TABLE course_programs (
  course_id       BIGINT UNSIGNED    NOT NULL,
  program_id      BIGINT UNSIGNED    NOT NULL,
  category        ENUM('core','elective','capstone','general_ed') NOT NULL DEFAULT 'elective',
  created_by      BIGINT UNSIGNED    NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (course_id, program_id),
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  FOREIGN KEY (program_id) REFERENCES degree_programs(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Curricular requirements mapping courses to degree pathways';

DROP TABLE IF EXISTS course_prerequisites;
CREATE TABLE course_prerequisites (
  course_id       BIGINT UNSIGNED    NOT NULL,
  prerequisite_id BIGINT UNSIGNED    NOT NULL,
  min_grade       VARCHAR(5)         NOT NULL DEFAULT 'C-',
  is_corequisite  BOOLEAN            NOT NULL DEFAULT 0,
  created_by      BIGINT UNSIGNED    NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (course_id, prerequisite_id),
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  FOREIGN KEY (prerequisite_id) REFERENCES courses(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Directed acyclic graph for course prerequisites and corequisites';

DROP TABLE IF EXISTS course_equivalencies;
CREATE TABLE course_equivalencies (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  course_id       BIGINT UNSIGNED    NOT NULL,
  equivalent_id   BIGINT UNSIGNED    NOT NULL,
  equiv_type      ENUM('cross_listed','mutually_exclusive','transfer_credit') NOT NULL DEFAULT 'cross_listed',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_equiv_pair           (course_id, equivalent_id),
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  FOREIGN KEY (equivalent_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Cross-listed courses across multidisciplinary departments (e.g. CS229 / STATS229)';

-- -----------------------------------------------------------------------------
-- 5. COURSE SECTIONS, SCHEDULING & REAL-TIME WAITLISTS
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS sections;
CREATE TABLE sections (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  course_id       BIGINT UNSIGNED    NOT NULL,
  term_id         BIGINT UNSIGNED    NOT NULL,
  section_no      VARCHAR(10)        NOT NULL,
  delivery_mode   ENUM('in_person','online_sync','online_async','hybrid') NOT NULL DEFAULT 'in_person',
  max_capacity    SMALLINT UNSIGNED  NOT NULL DEFAULT 30,
  waitlist_cap    SMALLINT UNSIGNED  NOT NULL DEFAULT 20,
  enrolled_count  SMALLINT UNSIGNED  NOT NULL DEFAULT 0,
  waitlist_count  SMALLINT UNSIGNED  NOT NULL DEFAULT 0,
  status          ENUM('open','closed','cancelled','waitlist_only') NOT NULL DEFAULT 'open',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_course_term_section  (course_id, term_id, section_no),
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Scheduled term-specific course offerings and capacity tracking';

DROP TABLE IF EXISTS section_instructors;
CREATE TABLE section_instructors (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  section_id      BIGINT UNSIGNED    NOT NULL,
  faculty_id      BIGINT UNSIGNED    NOT NULL,
  role            ENUM('primary_instructor','co_instructor','teaching_assistant','lab_instructor') NOT NULL DEFAULT 'primary_instructor',
  workload_pct    DECIMAL(5,2)       NOT NULL DEFAULT 100.00,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_section_faculty      (section_id, faculty_id),
  FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE,
  FOREIGN KEY (faculty_id) REFERENCES faculty(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Faculty and teaching assistants assigned to specific sections';

DROP TABLE IF EXISTS class_schedules;
CREATE TABLE class_schedules (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  section_id      BIGINT UNSIGNED    NOT NULL,
  room_id         BIGINT UNSIGNED    NULL,
  day_of_week     ENUM('Mon','Tue','Wed','Thu','Fri','Sat','Sun') NOT NULL,
  start_time      TIME               NOT NULL,
  end_time        TIME               NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE,
  FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL,
  CHECK (end_time > start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Room and timeslot reservations per class section';

DROP TABLE IF EXISTS enrollments;
CREATE TABLE enrollments (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  section_id      BIGINT UNSIGNED    NOT NULL,
  grading_option  ENUM('letter','pass_fail','audit') NOT NULL DEFAULT 'letter',
  enrolled_at     TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status          ENUM('enrolled','waitlisted','dropped','withdrawn','completed') NOT NULL DEFAULT 'enrolled',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  UNIQUE KEY uq_enrollment           (student_id, section_id),
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Student class enrollment state and lifecycle';

DROP TABLE IF EXISTS course_waitlists;
CREATE TABLE course_waitlists (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  section_id      BIGINT UNSIGNED    NOT NULL,
  position        SMALLINT UNSIGNED  NOT NULL DEFAULT 1 COMMENT 'FIFO priority queue position',
  status          ENUM('waiting','offered','declined','enrolled','expired') NOT NULL DEFAULT 'waiting',
  requested_at    TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  offer_expires_at TIMESTAMP         NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_student_section_wait (student_id, section_id),
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='FIFO queue for over-subscribed course section waitlists';

-- -----------------------------------------------------------------------------
-- 6. GRADING ENGINE, TRANSCRIPTS & ACADEMIC AUDIT
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS grade_scale;
CREATE TABLE grade_scale (
  id              TINYINT UNSIGNED   AUTO_INCREMENT PRIMARY KEY,
  grade           VARCHAR(5)         NOT NULL UNIQUE,
  gpa_points      DECIMAL(3,2)       NOT NULL,
  min_pct         DECIMAL(5,2)       NOT NULL,
  max_pct         DECIMAL(5,2)       NOT NULL,
  counts_in_gpa   BOOLEAN            NOT NULL DEFAULT 1,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Official university grade conversion scale (A+=4.0, A=4.0, A-=3.7, etc.)';

DROP TABLE IF EXISTS assignment_grades;
CREATE TABLE assignment_grades (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  enrollment_id   BIGINT UNSIGNED    NOT NULL,
  title           VARCHAR(100)       NOT NULL,
  score           DECIMAL(5,2)       NOT NULL DEFAULT 0.00,
  max_score       DECIMAL(5,2)       NOT NULL,
  weight          DECIMAL(4,2)       NOT NULL DEFAULT 1.00,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Course assignment, midterm, and quiz scores';

DROP TABLE IF EXISTS grades;
CREATE TABLE grades (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  enrollment_id   BIGINT UNSIGNED    NOT NULL UNIQUE,
  grade           VARCHAR(5)         NOT NULL,
  gpa_points      DECIMAL(3,2)       NOT NULL DEFAULT 0.00,
  credits_earned  DECIMAL(3,1)       NOT NULL DEFAULT 0.0,
  is_final        BOOLEAN            NOT NULL DEFAULT 0,
  submitted_by    BIGINT UNSIGNED    NULL,
  graded_at       TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE,
  FOREIGN KEY (submitted_by) REFERENCES faculty(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Final official course grades and GPA credit awards';

DROP TABLE IF EXISTS grade_change_logs;
CREATE TABLE grade_change_logs (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  grade_id        BIGINT UNSIGNED    NOT NULL,
  old_grade       VARCHAR(5)         NOT NULL,
  new_grade       VARCHAR(5)         NOT NULL,
  reason          VARCHAR(255)       NOT NULL,
  changed_by      BIGINT UNSIGNED    NOT NULL,
  changed_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='FERPA-mandated audit trail for any historical grade changes';

DROP TABLE IF EXISTS transcripts;
CREATE TABLE transcripts (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  term_id         BIGINT UNSIGNED    NOT NULL,
  cumulative_gpa  DECIMAL(4,3)       NOT NULL,
  total_credits   DECIMAL(5,1)       NOT NULL,
  snapshot        JSON               NOT NULL,
  sha256_hash     VARCHAR(64)        NOT NULL,
  generated_at    TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Cryptographically hashed historical transcript snapshots';

DROP TABLE IF EXISTS academic_warnings;
CREATE TABLE academic_warnings (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  term_id         BIGINT UNSIGNED    NOT NULL,
  reason          ENUM('low_gpa','attendance','probation','academic_dishonesty') NOT NULL,
  resolved        BOOLEAN            NOT NULL DEFAULT 0,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Student academic probation, warning, and standing records';

DROP TABLE IF EXISTS advising_relationships;
CREATE TABLE advising_relationships (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  faculty_id      BIGINT UNSIGNED    NOT NULL,
  student_id      BIGINT UNSIGNED    NOT NULL,
  advising_type   ENUM('major_advisor','thesis_advisor','academic_dean') NOT NULL DEFAULT 'major_advisor',
  start_date      DATE               NOT NULL,
  end_date        DATE               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (faculty_id) REFERENCES faculty(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Student-to-faculty academic and research advising relationships';

-- -----------------------------------------------------------------------------
-- 7. CAMPUS ASSETS, EQUIPMENT & MAINTENANCE
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS equipment;
CREATE TABLE equipment (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  room_id         BIGINT UNSIGNED    NOT NULL,
  asset_tag       VARCHAR(50)        NOT NULL UNIQUE,
  name            VARCHAR(100)       NOT NULL,
  purchased_at    DATE               NOT NULL,
  purchase_cost   DECIMAL(10,2)      NULL,
  status          ENUM('operational','maintenance','decommissioned') NOT NULL DEFAULT 'operational',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Laboratory, server room, and high-value research equipment';

DROP TABLE IF EXISTS maintenance_logs;
CREATE TABLE maintenance_logs (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  equipment_id    BIGINT UNSIGNED    NOT NULL,
  log_date        DATE               NOT NULL,
  cost            DECIMAL(10,2)      NOT NULL DEFAULT 0.00,
  notes           TEXT               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Equipment service, repair, and calibration records';

-- -----------------------------------------------------------------------------
-- 8. UNIVERSITY LIBRARIES & SCHOLARLY CIRCULATION
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS publishers;
CREATE TABLE publishers (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(255)       NOT NULL UNIQUE,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS authors;
CREATE TABLE authors (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(255)       NOT NULL UNIQUE,
  orcid           VARCHAR(30)        NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS library_books;
CREATE TABLE library_books (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  isbn            VARCHAR(20)        NOT NULL UNIQUE,
  title           VARCHAR(255)       NOT NULL,
  publisher_id    BIGINT UNSIGNED    NULL,
  copies_total    INT UNSIGNED       NOT NULL DEFAULT 1,
  copies_avail    INT UNSIGNED       NOT NULL DEFAULT 1,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  FOREIGN KEY (publisher_id) REFERENCES publishers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS book_authors;
CREATE TABLE book_authors (
  book_id         BIGINT UNSIGNED    NOT NULL,
  author_id       BIGINT UNSIGNED    NOT NULL,
  created_by      BIGINT UNSIGNED    NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (book_id, author_id),
  FOREIGN KEY (book_id) REFERENCES library_books(id) ON DELETE CASCADE,
  FOREIGN KEY (author_id) REFERENCES authors(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS book_checkouts;
CREATE TABLE book_checkouts (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED    NOT NULL,
  book_id         BIGINT UNSIGNED    NOT NULL,
  loaned_at       TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_at          DATE               NOT NULL,
  returned_at     TIMESTAMP          NULL,
  fine_amount     DECIMAL(6,2)       NOT NULL DEFAULT 0.00,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (book_id) REFERENCES library_books(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

-- -----------------------------------------------------------------------------
-- 9. RESIDENTIAL LIFE & HOUSING
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS dormitories;
CREATE TABLE dormitories (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  campus_id       SMALLINT UNSIGNED  NOT NULL,
  name            VARCHAR(100)       NOT NULL UNIQUE,
  capacity        SMALLINT UNSIGNED  NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (campus_id) REFERENCES campuses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS housing_assignments;
CREATE TABLE housing_assignments (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  dormitory_id    BIGINT UNSIGNED    NOT NULL,
  room_number     VARCHAR(10)        NOT NULL,
  assigned_from   DATE               NOT NULL,
  assigned_to     DATE               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (dormitory_id) REFERENCES dormitories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS room_inspections;
CREATE TABLE room_inspections (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  dormitory_id    BIGINT UNSIGNED    NOT NULL,
  room_number     VARCHAR(10)        NOT NULL,
  inspection_date DATE               NOT NULL,
  passed          BOOLEAN            NOT NULL DEFAULT 0,
  notes           TEXT               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (dormitory_id) REFERENCES dormitories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

-- -----------------------------------------------------------------------------
-- 10. UNIVERSITY FINANCE & TUITION LEDGER
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS tuition_fees;
CREATE TABLE tuition_fees (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  program_id      BIGINT UNSIGNED    NOT NULL,
  term_id         BIGINT UNSIGNED    NOT NULL,
  amount          DECIMAL(12,2)      NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (program_id) REFERENCES degree_programs(id) ON DELETE CASCADE,
  FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS invoices;
CREATE TABLE invoices (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  term_id         BIGINT UNSIGNED    NOT NULL,
  invoice_number  VARCHAR(30)        NOT NULL UNIQUE,
  total_amount    DECIMAL(12,2)      NOT NULL,
  paid_amount     DECIMAL(12,2)      NOT NULL DEFAULT 0.00,
  status          ENUM('unpaid','partial','paid','cancelled') NOT NULL DEFAULT 'unpaid',
  due_date        DATE               NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT,
  FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci
COMMENT='Official student tuition and fee statements';

DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  invoice_id      BIGINT UNSIGNED    NULL,
  transaction_ref VARCHAR(50)        NOT NULL UNIQUE,
  amount          DECIMAL(12,2)      NOT NULL,
  paid_at         TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  method          ENUM('credit_card','bank_transfer','cash','check','wire') NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS financial_aid;
CREATE TABLE financial_aid (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  award_name      VARCHAR(255)       NOT NULL,
  amount          DECIMAL(12,2)      NOT NULL,
  awarded_date    DATE               NOT NULL,
  renewal_term    BIGINT UNSIGNED    NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (renewal_term) REFERENCES terms(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS scholarships;
CREATE TABLE scholarships (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  award_name      VARCHAR(255)       NOT NULL,
  amount          DECIMAL(12,2)      NOT NULL,
  awarded_date    DATE               NOT NULL,
  renewal_term_id BIGINT UNSIGNED    NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (renewal_term_id) REFERENCES terms(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS payroll;
CREATE TABLE payroll (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  staff_id        BIGINT UNSIGNED    NOT NULL,
  pay_period      VARCHAR(20)        NOT NULL,
  gross_amount    DECIMAL(12,2)      NOT NULL,
  net_amount      DECIMAL(12,2)      NOT NULL,
  deductions      JSON               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS vendor_payments;
CREATE TABLE vendor_payments (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  vendor_name     VARCHAR(100)       NOT NULL,
  amount          DECIMAL(12,2)      NOT NULL,
  purpose         VARCHAR(200)       NOT NULL,
  approved_by     BIGINT UNSIGNED    NULL COMMENT 'Nullable to support ON DELETE SET NULL safely',
  payment_date    DATE               NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS endowment_funds;
CREATE TABLE endowment_funds (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  fund_name       VARCHAR(100)       NOT NULL UNIQUE,
  purpose         TEXT               NOT NULL,
  current_value   DECIMAL(16,2)      NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

-- -----------------------------------------------------------------------------
-- 11. STUDENT LIFE, ATHLETICS & HEALTH
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS student_organizations;
CREATE TABLE student_organizations (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(100)       NOT NULL UNIQUE,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS organization_memberships;
CREATE TABLE organization_memberships (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  org_id          BIGINT UNSIGNED    NOT NULL,
  user_id         BIGINT UNSIGNED    NOT NULL,
  role            VARCHAR(50)        NULL,
  joined_at       DATE               NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES student_organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS health_records;
CREATE TABLE health_records (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED    NOT NULL,
  record          JSON               NOT NULL,
  is_sensitive    BOOLEAN            NOT NULL DEFAULT 1,
  access_key      VARCHAR(64)        NOT NULL,
  recorded_at     TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS athletic_teams;
CREATE TABLE athletic_teams (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(100)       NOT NULL UNIQUE,
  sport           VARCHAR(50)        NOT NULL,
  ncaa_id         VARCHAR(20)        UNIQUE,
  division        ENUM('D1','D2','D3','NAIA') NOT NULL DEFAULT 'D1',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS team_rosters;
CREATE TABLE team_rosters (
  team_id         BIGINT UNSIGNED    NOT NULL,
  user_id         BIGINT UNSIGNED    NOT NULL,
  role            VARCHAR(50)        NULL,
  created_by      BIGINT UNSIGNED    NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (team_id, user_id),
  FOREIGN KEY (team_id) REFERENCES athletic_teams(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS campus_events;
CREATE TABLE campus_events (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  title           VARCHAR(100)       NOT NULL,
  organizer_id    BIGINT UNSIGNED    NULL COMMENT 'Nullable to support ON DELETE SET NULL safely',
  location        VARCHAR(100)       NOT NULL,
  event_date      DATETIME           NOT NULL,
  description     TEXT               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (organizer_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS event_attendance;
CREATE TABLE event_attendance (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  event_id        BIGINT UNSIGNED    NOT NULL,
  user_id         BIGINT UNSIGNED    NOT NULL,
  check_in        TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (event_id) REFERENCES campus_events(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS dining_plans;
CREATE TABLE dining_plans (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL UNIQUE,
  plan_type       ENUM('basic','premium','athlete','commuter') NOT NULL,
  balance         DECIMAL(8,2)       NOT NULL DEFAULT 0.00,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

-- -----------------------------------------------------------------------------
-- 12. SPONSORED RESEARCH & INTELLECTUAL PROPERTY
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS research_labs;
CREATE TABLE research_labs (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(100)       NOT NULL UNIQUE,
  department_id   BIGINT UNSIGNED    NOT NULL,
  location        VARCHAR(100)       NULL,
  director_id     BIGINT UNSIGNED    NOT NULL,
  annual_budget   DECIMAL(14,2)      NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP          NULL,
  FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
  FOREIGN KEY (director_id) REFERENCES faculty(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS research_grants;
CREATE TABLE research_grants (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  lab_id          BIGINT UNSIGNED    NOT NULL,
  grant_number    VARCHAR(50)        NOT NULL UNIQUE,
  funding_agency  VARCHAR(100)       NOT NULL,
  amount          DECIMAL(14,2)      NOT NULL,
  start_date      DATE               NOT NULL,
  end_date        DATE               NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (lab_id) REFERENCES research_labs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS lab_memberships;
CREATE TABLE lab_memberships (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  lab_id          BIGINT UNSIGNED    NOT NULL,
  user_id         BIGINT UNSIGNED    NOT NULL,
  user_type       ENUM('faculty','student','postdoc','visiting_scholar') NOT NULL,
  role            VARCHAR(50)        NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (lab_id) REFERENCES research_labs(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS publications;
CREATE TABLE publications (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  lab_id          BIGINT UNSIGNED    NOT NULL,
  title           VARCHAR(255)       NOT NULL,
  journal         VARCHAR(255)       NULL,
  doi             VARCHAR(100)       NULL,
  published_at    DATE               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (lab_id) REFERENCES research_labs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS patent_records;
CREATE TABLE patent_records (
  id               BIGINT UNSIGNED   AUTO_INCREMENT PRIMARY KEY,
  invention_title  VARCHAR(200)      NOT NULL,
  inventors        JSON              NOT NULL,
  filing_date      DATE              NOT NULL,
  patent_number    VARCHAR(50)       NULL UNIQUE,
  licensing_status ENUM('pending','licensed','expired','abandoned') NULL,
  created_at       TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS research_inventions;
CREATE TABLE research_inventions (
  id                       BIGINT UNSIGNED   AUTO_INCREMENT PRIMARY KEY,
  patent_id                BIGINT UNSIGNED   NOT NULL,
  inventor_id              BIGINT UNSIGNED   NOT NULL,
  contribution_percentage  DECIMAL(5,2)      NOT NULL,
  created_at               TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (patent_id) REFERENCES patent_records(id) ON DELETE CASCADE,
  FOREIGN KEY (inventor_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

-- -----------------------------------------------------------------------------
-- 13. SAFETY, ADMIN, AUDIT & CONFIGURATION
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS audit_logs;
CREATE TABLE audit_logs (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED    NULL,
  auditable_type  VARCHAR(100)       NOT NULL,
  auditable_id    BIGINT UNSIGNED    NOT NULL,
  action          VARCHAR(50)        NOT NULL,
  old_values      JSON               NULL,
  new_values      JSON               NULL,
  ip_address      VARCHAR(45)        NULL,
  user_agent      TEXT               NULL,
  ferpa_related   BOOLEAN            NOT NULL DEFAULT 0,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS access_controls;
CREATE TABLE access_controls (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED    NOT NULL,
  resource        VARCHAR(100)       NOT NULL,
  permission      VARCHAR(50)        NOT NULL,
  granted_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS emergency_contacts;
CREATE TABLE emergency_contacts (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED    NOT NULL,
  name            VARCHAR(100)       NOT NULL,
  phone           VARCHAR(20)        NOT NULL,
  relation        VARCHAR(50)        NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS incident_reports;
CREATE TABLE incident_reports (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  reporter_id     BIGINT UNSIGNED    NULL COMMENT 'Nullable to support ON DELETE SET NULL safely',
  incident_at     DATETIME           NOT NULL,
  details         TEXT               NOT NULL,
  status          ENUM('open','investigating','closed') NOT NULL DEFAULT 'open',
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS system_config;
CREATE TABLE system_config (
  `key`           VARCHAR(100)       PRIMARY KEY,
  `value`         TEXT               NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS data_retention_policies;
CREATE TABLE data_retention_policies (
  id                  BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  table_name          VARCHAR(50)        NOT NULL UNIQUE,
  retention_period    SMALLINT           NOT NULL COMMENT 'Retention period in years',
  disposal_protocol   ENUM('shred','anonymize','archive') NOT NULL,
  created_at          TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS accreditation_standards;
CREATE TABLE accreditation_standards (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  program_id      BIGINT UNSIGNED    NOT NULL,
  standard_code   VARCHAR(20)        NOT NULL,
  description     TEXT               NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (program_id) REFERENCES degree_programs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS accreditation_records;
CREATE TABLE accreditation_records (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  program_id      BIGINT UNSIGNED    NOT NULL,
  report_year     YEAR               NOT NULL,
  status          ENUM('compliant','warning','deficient') NOT NULL,
  report_url      VARCHAR(255)       NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (program_id) REFERENCES degree_programs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

-- -----------------------------------------------------------------------------
-- 14. INTERNATIONAL PROGRAMS & VISAS
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS study_abroad_programs;
CREATE TABLE study_abroad_programs (
  id                   BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  name                 VARCHAR(100)       NOT NULL,
  host_institution     VARCHAR(100)       NOT NULL,
  country              VARCHAR(50)        NOT NULL,
  credits_transferable BOOLEAN            NOT NULL DEFAULT 1,
  created_at           TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS exchange_students;
CREATE TABLE exchange_students (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  program_id      BIGINT UNSIGNED    NOT NULL,
  term_id         BIGINT UNSIGNED    NOT NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (program_id) REFERENCES study_abroad_programs(id) ON DELETE CASCADE,
  FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS visa_records;
CREATE TABLE visa_records (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  visa_type       VARCHAR(50)        NOT NULL,
  expiration_date DATE               NOT NULL,
  i20_number      VARCHAR(50)        NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS language_proficiency;
CREATE TABLE language_proficiency (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT UNSIGNED    NOT NULL,
  language        VARCHAR(50)        NOT NULL,
  level           ENUM('A1','A2','B1','B2','C1','C2') NULL,
  certification   VARCHAR(50)        NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

DROP TABLE IF EXISTS cultural_adaptation;
CREATE TABLE cultural_adaptation (
  id              BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  student_id      BIGINT UNSIGNED    NOT NULL,
  advisor_id      BIGINT UNSIGNED    NULL COMMENT 'Nullable to support ON DELETE SET NULL safely',
  session_date    DATE               NOT NULL,
  notes           TEXT               NULL,
  created_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (advisor_id) REFERENCES staff(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

SET FOREIGN_KEY_CHECKS = 1;


-- #############################################################################
-- TIER-1 UNIVERSITY ENTERPRISE DATABASE ARCHITECTURE
-- Performance Indexing, Composite Lookup Paths & Full-Text Search
-- #############################################################################

-- 1. Academic & Student Lifecycle Lookups
CREATE INDEX idx_student_program_status    ON students(program_id, status);
CREATE INDEX idx_student_user_lookup       ON students(user_id);
CREATE INDEX idx_student_programs_lookup   ON student_programs(student_id, status);
CREATE INDEX idx_advising_faculty_student  ON advising_relationships(faculty_id, student_id);

-- 2. Course Catalog & Curricular Indexing
CREATE INDEX idx_course_department_code    ON courses(department_id, code);
CREATE INDEX idx_course_prereqs_graph      ON course_prerequisites(course_id, prerequisite_id);
CREATE INDEX idx_course_equiv_bidirectional ON course_equivalencies(course_id, equivalent_id);
CREATE FULLTEXT INDEX ft_course_search     ON courses(title, description);

-- 3. Term Sections, Capacity & Schedule Conflict Resolution
CREATE INDEX idx_sections_term_course      ON sections(term_id, course_id, status);
CREATE INDEX idx_sections_capacity_gate    ON sections(status, enrolled_count, max_capacity);
CREATE INDEX idx_class_schedules_conflict  ON class_schedules(day_of_week, start_time, end_time, room_id);
CREATE INDEX idx_sec_instructors_faculty   ON section_instructors(faculty_id, section_id);

-- 4. Enrollments, Grading & Waitlist Queuing
CREATE INDEX idx_enrollment_student_status ON enrollments(student_id, status);
CREATE INDEX idx_enrollment_section_status ON enrollments(section_id, status);
CREATE INDEX idx_waitlist_fifo_queue       ON course_waitlists(section_id, status, position);
CREATE INDEX idx_assignment_grades_enroll  ON assignment_grades(enrollment_id);
CREATE INDEX idx_grades_final_status       ON grades(enrollment_id, is_final);
CREATE INDEX idx_transcripts_student_term  ON transcripts(student_id, term_id);

-- 5. Finance, Invoicing & Tuition Auditing
CREATE INDEX idx_tuition_program_term      ON tuition_fees(program_id, term_id);
CREATE INDEX idx_invoices_student_status   ON invoices(student_id, status, due_date);
CREATE INDEX idx_payments_student_date     ON payments(student_id, paid_at);
CREATE INDEX idx_vendor_payments_date      ON vendor_payments(payment_date, status);
CREATE INDEX idx_payroll_staff_period      ON payroll(staff_id, pay_period);

-- 6. Sponsored Research & Intellectual Property
CREATE INDEX idx_labs_department           ON research_labs(department_id);
CREATE INDEX idx_labs_director             ON research_labs(director_id);
CREATE INDEX idx_grants_lab_dates          ON research_grants(lab_id, start_date, end_date);
CREATE INDEX idx_publications_lab_date     ON publications(lab_id, published_at);
CREATE FULLTEXT INDEX ft_pub_search        ON publications(title, journal);
CREATE INDEX idx_patents_filing_status     ON patent_records(filing_date, licensing_status);

-- 7. Facilities, Housing & Library Circulation
CREATE INDEX idx_rooms_building_cap        ON rooms(building_id, capacity);
CREATE INDEX idx_equipment_room_status     ON equipment(room_id, status);
CREATE INDEX idx_housing_student_dorm      ON housing_assignments(student_id, dormitory_id);
CREATE INDEX idx_book_checkouts_due        ON book_checkouts(user_id, due_at, returned_at);
CREATE FULLTEXT INDEX ft_library_search    ON library_books(title);

-- 8. Compliance, FERPA & Security Audits
CREATE INDEX idx_audit_time_entity         ON audit_logs(created_at, auditable_type, auditable_id);
CREATE INDEX idx_audit_ferpa_flags         ON audit_logs(ferpa_related, created_at);
CREATE INDEX idx_health_records_user       ON health_records(user_id, is_sensitive);
CREATE INDEX idx_visa_student_expiry       ON visa_records(student_id, expiration_date);


-- #############################################################################
-- TIER-1 UNIVERSITY ENTERPRISE DATABASE ARCHITECTURE
-- Analytical Views, Materialized Reporting & Real-Time Academic Queries
-- #############################################################################

-- -----------------------------------------------------------------------------
-- 1. Student Academic Standing & Real-Time GPA View
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_student_academic_summary AS
SELECT 
    s.id AS student_id,
    s.student_number,
    u.name AS student_name,
    u.email AS student_email,
    dp.name AS program_name,
    dp.level AS program_level,
    s.status AS enrollment_status,
    COUNT(DISTINCT e.id) AS total_courses_enrolled,
    COALESCE(SUM(c.credits), 0) AS total_credits_attempted,
    COALESCE(SUM(CASE WHEN g.gpa_points > 0.0 OR g.grade IN ('CR','P','S') THEN c.credits ELSE 0 END), 0) AS total_credits_earned,
    ROUND(COALESCE(SUM(g.gpa_points * c.credits) / NULLIF(SUM(CASE WHEN gs.counts_in_gpa = 1 THEN c.credits ELSE 0 END), 0), 0.000), 3) AS cumulative_gpa,
    s.enrollment_date,
    s.graduation_date
FROM students s
JOIN users u ON s.user_id = u.id
LEFT JOIN degree_programs dp ON s.program_id = dp.id
LEFT JOIN enrollments e ON s.id = e.student_id AND e.status IN ('enrolled','completed')
LEFT JOIN sections sec ON e.section_id = sec.id
LEFT JOIN courses c ON sec.course_id = c.id
LEFT JOIN grades g ON e.id = g.enrollment_id AND g.is_final = 1
LEFT JOIN grade_scale gs ON g.grade = gs.grade
GROUP BY s.id, s.student_number, u.name, u.email, dp.name, dp.level, s.status, s.enrollment_date, s.graduation_date;

-- -----------------------------------------------------------------------------
-- 2. Real-Time Section Capacity & Waitlist Utilization
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_course_section_availability AS
SELECT 
    sec.id AS section_id,
    t.code AS term_code,
    c.code AS course_code,
    c.title AS course_title,
    sec.section_no,
    sec.delivery_mode,
    sec.max_capacity,
    sec.enrolled_count,
    (sec.max_capacity - sec.enrolled_count) AS available_seats,
    ROUND((sec.enrolled_count / NULLIF(sec.max_capacity, 0)) * 100, 1) AS seat_utilization_pct,
    sec.waitlist_cap,
    sec.waitlist_count,
    sec.status AS section_status,
    COALESCE(u_fac.name, 'Staff') AS primary_instructor,
    CONCAT(COALESCE(b.code, 'TBA'), ' ', COALESCE(r.room_no, 'TBA')) AS room_location
FROM sections sec
JOIN terms t ON sec.term_id = t.id
JOIN courses c ON sec.course_id = c.id
LEFT JOIN section_instructors si ON sec.id = si.section_id AND si.role = 'primary_instructor'
LEFT JOIN faculty f ON si.faculty_id = f.id
LEFT JOIN users u_fac ON f.user_id = u_fac.id
LEFT JOIN class_schedules cs ON sec.id = cs.section_id
LEFT JOIN rooms r ON cs.room_id = r.id
LEFT JOIN buildings b ON r.building_id = b.id
GROUP BY sec.id, t.code, c.code, c.title, sec.section_no, sec.delivery_mode, sec.max_capacity, 
         sec.enrolled_count, sec.waitlist_cap, sec.waitlist_count, sec.status, u_fac.name, b.code, r.room_no;

-- -----------------------------------------------------------------------------
-- 3. Student Account Balance & Financial Ledger
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_student_financial_ledger AS
SELECT 
    s.id AS student_id,
    s.student_number,
    u.name AS student_name,
    COALESCE(inv_totals.total_invoiced, 0.00) AS total_invoiced,
    COALESCE(pay_totals.total_paid, 0.00) AS total_payments,
    COALESCE(aid_totals.total_aid_awarded, 0.00) AS total_financial_aid,
    ROUND(COALESCE(inv_totals.total_invoiced, 0.00) - COALESCE(pay_totals.total_paid, 0.00), 2) AS outstanding_balance
FROM students s
JOIN users u ON s.user_id = u.id
LEFT JOIN (
    SELECT student_id, SUM(total_amount) AS total_invoiced
    FROM invoices
    WHERE status != 'cancelled'
    GROUP BY student_id
) inv_totals ON s.id = inv_totals.student_id
LEFT JOIN (
    SELECT student_id, SUM(amount) AS total_paid
    FROM payments
    GROUP BY student_id
) pay_totals ON s.id = pay_totals.student_id
LEFT JOIN (
    SELECT student_id, SUM(amount) AS total_aid_awarded
    FROM financial_aid
    GROUP BY student_id
) aid_totals ON s.id = aid_totals.student_id;

-- -----------------------------------------------------------------------------
-- 4. Sponsored Research Grants & Portfolio Overview
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_research_portfolio_summary AS
SELECT 
    rl.id AS lab_id,
    rl.name AS lab_name,
    d.name AS department_name,
    u_dir.name AS lab_director,
    COUNT(DISTINCT rg.id) AS total_grants,
    COALESCE(SUM(rg.amount), 0.00) AS total_grant_funding,
    COALESCE(SUM(CASE WHEN CURDATE() BETWEEN rg.start_date AND rg.end_date THEN rg.amount ELSE 0 END), 0.00) AS active_grant_funding,
    COUNT(DISTINCT lm.user_id) AS total_researchers,
    COUNT(DISTINCT p.id) AS total_publications
FROM research_labs rl
JOIN departments d ON rl.department_id = d.id
JOIN faculty f ON rl.director_id = f.id
JOIN users u_dir ON f.user_id = u_dir.id
LEFT JOIN research_grants rg ON rl.id = rg.lab_id
LEFT JOIN lab_memberships lm ON rl.id = lm.lab_id
LEFT JOIN publications p ON rl.id = p.lab_id
GROUP BY rl.id, rl.name, d.name, u_dir.name;


-- #############################################################################
-- TIER-1 UNIVERSITY ENTERPRISE DATABASE ARCHITECTURE
-- Stored Procedures, Automated Waitlist Promotion & Audit Triggers
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. High-Integrity Student Enrollment Engine with Prerequisite & Conflict Checks
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_enroll_student_in_section $$
CREATE PROCEDURE sp_enroll_student_in_section(
    IN p_student_id BIGINT UNSIGNED,
    IN p_section_id BIGINT UNSIGNED,
    OUT p_result_code VARCHAR(30),
    OUT p_result_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_course_id BIGINT UNSIGNED;
    DECLARE v_term_id BIGINT UNSIGNED;
    DECLARE v_max_cap SMALLINT UNSIGNED;
    DECLARE v_enrolled_cnt SMALLINT UNSIGNED;
    DECLARE v_waitlist_cap SMALLINT UNSIGNED;
    DECLARE v_waitlist_cnt SMALLINT UNSIGNED;
    DECLARE v_unmet_prereqs INT DEFAULT 0;
    DECLARE v_schedule_conflicts INT DEFAULT 0;
    DECLARE v_already_enrolled INT DEFAULT 0;
    DECLARE v_next_wait_pos SMALLINT UNSIGNED;

    -- A. Validate section existence and capacity
    SELECT course_id, term_id, max_capacity, enrolled_count, waitlist_cap, waitlist_count
    INTO v_course_id, v_term_id, v_max_cap, v_enrolled_cnt, v_waitlist_cap, v_waitlist_cnt
    FROM sections
    WHERE id = p_section_id;

    IF v_course_id IS NULL THEN
        SET p_result_code = 'ERROR_SECTION_NOT_FOUND';
        SET p_result_message = 'The specified course section does not exist.';
        LEAVE proc_label;
    END IF;

    -- B. Verify if student is already enrolled in this section or another section of the same course
    SELECT COUNT(*) INTO v_already_enrolled
    FROM enrollments e
    JOIN sections s ON e.section_id = s.id
    WHERE e.student_id = p_student_id 
      AND s.course_id = v_course_id 
      AND s.term_id = v_term_id 
      AND e.status IN ('enrolled','completed');

    IF v_already_enrolled > 0 THEN
        SET p_result_code = 'ALREADY_ENROLLED';
        SET p_result_message = 'Student is already enrolled in this course for the selected term.';
        LEAVE proc_label;
    END IF;

    -- C. Validate Prerequisites (Directed Acyclic Graph Verification)
    SELECT COUNT(*) INTO v_unmet_prereqs
    FROM course_prerequisites cp
    WHERE cp.course_id = v_course_id
      AND cp.prerequisite_id NOT IN (
          SELECT sec.course_id
          FROM enrollments enr
          JOIN sections sec ON enr.section_id = sec.id
          JOIN grades gr ON enr.id = gr.enrollment_id
          WHERE enr.student_id = p_student_id 
            AND gr.is_final = 1 
            AND gr.grade NOT IN ('F','W','NP')
      );

    IF v_unmet_prereqs > 0 THEN
        SET p_result_code = 'PREREQUISITE_NOT_MET';
        SET p_result_message = 'Student has not fulfilled all mandatory prerequisite courses.';
        LEAVE proc_label;
    END IF;

    -- D. Check Time & Room Schedule Overlaps (Conflict Detection)
    SELECT COUNT(*) INTO v_schedule_conflicts
    FROM class_schedules target_cs
    JOIN class_schedules existing_cs ON target_cs.day_of_week = existing_cs.day_of_week
         AND (target_cs.start_time < existing_cs.end_time AND target_cs.end_time > existing_cs.start_time)
    JOIN enrollments e ON existing_cs.section_id = e.section_id
    JOIN sections existing_sec ON e.section_id = existing_sec.id
    WHERE target_cs.section_id = p_section_id
      AND e.student_id = p_student_id
      AND existing_sec.term_id = v_term_id
      AND e.status = 'enrolled';

    IF v_schedule_conflicts > 0 THEN
        SET p_result_code = 'SCHEDULE_CONFLICT';
        SET p_result_message = 'Selected section timetable conflicts with an existing enrolled class.';
        LEAVE proc_label;
    END IF;

    -- E. Evaluate Capacity & Allocate Seat or Waitlist
    START TRANSACTION;

    IF v_enrolled_cnt < v_max_cap THEN
        -- Seat available: Enroll student
        INSERT INTO enrollments (student_id, section_id, status)
        VALUES (p_student_id, p_section_id, 'enrolled');

        UPDATE sections
        SET enrolled_count = enrolled_count + 1
        WHERE id = p_section_id;

        SET p_result_code = 'SUCCESS_ENROLLED';
        SET p_result_message = 'Student successfully enrolled in section.';
    ELSEIF v_waitlist_cnt < v_waitlist_cap THEN
        -- Section full, add to FIFO waitlist queue
        SELECT COALESCE(MAX(position), 0) + 1 INTO v_next_wait_pos
        FROM course_waitlists
        WHERE section_id = p_section_id AND status = 'waiting';

        INSERT INTO course_waitlists (student_id, section_id, position, status)
        VALUES (p_student_id, p_section_id, v_next_wait_pos, 'waiting');

        UPDATE sections
        SET waitlist_count = waitlist_count + 1
        WHERE id = p_section_id;

        SET p_result_code = 'SUCCESS_WAITLISTED';
        SET p_result_message = CONCAT('Section is full. Student placed on waitlist at position #', v_next_wait_pos);
    ELSE
        SET p_result_code = 'SECTION_FULL';
        SET p_result_message = 'Both the course section and its waitlist capacity are fully exhausted.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;

    COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- 2. Automated FIFO Waitlist Promotion Procedure
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_promote_waitlist_candidate $$
CREATE PROCEDURE sp_promote_waitlist_candidate(
    IN p_section_id BIGINT UNSIGNED,
    OUT p_promoted_student_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_waitlist_id BIGINT UNSIGNED;
    DECLARE v_candidate_student_id BIGINT UNSIGNED;

    -- Identify top priority waiting candidate
    SELECT id, student_id INTO v_waitlist_id, v_candidate_student_id
    FROM course_waitlists
    WHERE section_id = p_section_id AND status = 'waiting'
    ORDER BY position ASC
    LIMIT 1;

    IF v_candidate_student_id IS NOT NULL THEN
        START TRANSACTION;

        -- Promote from waitlist to enrolled
        UPDATE course_waitlists 
        SET status = 'enrolled', offer_expires_at = NOW()
        WHERE id = v_waitlist_id;

        INSERT INTO enrollments (student_id, section_id, status)
        VALUES (v_candidate_student_id, p_section_id, 'enrolled');

        -- Update section counters
        UPDATE sections
        SET enrolled_count = enrolled_count + 1,
            waitlist_count = GREATEST(0, waitlist_count - 1)
        WHERE id = p_section_id;

        -- Shift remaining positions up by 1
        UPDATE course_waitlists
        SET position = position - 1
        WHERE section_id = p_section_id AND status = 'waiting';

        COMMIT;
        SET p_promoted_student_id = v_candidate_student_id;
    ELSE
        SET p_promoted_student_id = NULL;
    END IF;
END $$

-- -----------------------------------------------------------------------------
-- 3. Trigger: FERPA Grade Modification Audit Trail
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_grade_modification $$
CREATE TRIGGER trg_audit_grade_modification
AFTER UPDATE ON grades
FOR EACH ROW
BEGIN
    IF OLD.grade <> NEW.grade OR OLD.gpa_points <> NEW.gpa_points THEN
        INSERT INTO grade_change_logs (
            grade_id,
            old_grade,
            new_grade,
            reason,
            changed_by,
            changed_at
        ) VALUES (
            OLD.id,
            OLD.grade,
            NEW.grade,
            'Automated Trigger: Grade altered post-submission',
            COALESCE(NEW.submitted_by, 1),
            CURRENT_TIMESTAMP
        );

        INSERT INTO audit_logs (
            user_id,
            auditable_type,
            auditable_id,
            action,
            old_values,
            new_values,
            ferpa_related
        ) VALUES (
            NEW.submitted_by,
            'Grade',
            OLD.id,
            'GRADE_UPDATE',
            JSON_OBJECT('grade', OLD.grade, 'gpa_points', OLD.gpa_points),
            JSON_OBJECT('grade', NEW.grade, 'gpa_points', NEW.gpa_points),
            1
        );
    END IF;
END $$

DELIMITER ;

