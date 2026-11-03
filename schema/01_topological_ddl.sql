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
