-- #############################################################################
-- TIER-1 UNIVERSITY ENTERPRISE DATABASE ARCHITECTURE
-- Production Validation Seed Data: Stanford-Grade Academic Ecosystem
-- #############################################################################

-- 1. Campuses & Facilities
INSERT INTO campuses (name, code, location, timezone) VALUES
('Main Quad Campus', 'MAIN', 'Stanford, CA 94305', 'America/Los_Angeles'),
('Medical Center & Clinics', 'MED', 'Pasteur Drive, Stanford, CA', 'America/Los_Angeles'),
('Redwood City Innovation Campus', 'RWC', 'Broadway, Redwood City, CA', 'America/Los_Angeles');

INSERT INTO buildings (campus_id, code, name, total_floors) VALUES
(1, 'GATES', 'William Gates Computer Science Building', 4),
(1, 'PACKARD', 'David Packard Electrical Engineering Building', 3),
(1, 'HUANG', 'Jen-Hsun Huang Engineering Center', 4),
(1, 'GREEN', 'Green Library & Special Collections', 5),
(2, 'LKS', 'Li Ka Shing Center for Learning & Knowledge', 5);

INSERT INTO rooms (building_id, room_no, room_type, capacity, has_projector, is_accessible) VALUES
(1, 'B01', 'lecture_hall', 180, 1, 1),
(1, 'B03', 'lab', 45, 1, 1),
(1, '392', 'office', 4, 0, 1),
(2, '101', 'auditorium', 250, 1, 1),
(3, '300', 'seminar', 35, 1, 1),
(4, '210', 'study', 60, 0, 1);

-- 2. Grade Scale Matrix
INSERT INTO grade_scale (grade, gpa_points, min_pct, max_pct, counts_in_gpa) VALUES
('A+', 4.00, 97.00, 100.00, 1),
('A',  4.00, 93.00, 96.99, 1),
('A-', 3.70, 90.00, 92.99, 1),
('B+', 3.30, 87.00, 89.99, 1),
('B',  3.00, 83.00, 86.99, 1),
('B-', 2.70, 80.00, 82.99, 1),
('C+', 2.30, 77.00, 79.99, 1),
('C',  2.00, 73.00, 76.99, 1),
('C-', 1.70, 70.00, 72.99, 1),
('D',  1.00, 60.00, 69.99, 1),
('F',  0.00, 0.00,  59.99, 1),
('P',  0.00, 70.00, 100.00, 0),
('NP', 0.00, 0.00,  69.99, 0);

-- 3. Departments & Degree Programs
INSERT INTO departments (campus_id, code, name, budget_code) VALUES
(1, 'CS', 'Computer Science', 'ENG-CS-4401'),
(1, 'EE', 'Electrical Engineering', 'ENG-EE-4402'),
(1, 'ME', 'Mechanical Engineering', 'ENG-ME-4403'),
(1, 'BIOE', 'Bioengineering', 'ENG-BIOE-4404'),
(1, 'ECON', 'Economics', 'H&S-ECON-2201'),
(2, 'MED', 'School of Medicine', 'MED-GEN-9901');

INSERT INTO degree_programs (department_id, code, name, level, duration_months, total_credits) VALUES
(1, 'BS-CS', 'Bachelor of Science in Computer Science', 'BSc', 48, 180.0),
(1, 'MS-CS', 'Master of Science in Computer Science', 'MSc', 24, 45.0),
(1, 'PHD-CS', 'Doctor of Philosophy in Computer Science', 'PhD', 60, 135.0),
(4, 'BS-BIOE', 'Bachelor of Science in Bioengineering', 'BSc', 48, 180.0),
(5, 'BA-ECON', 'Bachelor of Arts in Economics', 'BA', 48, 180.0),
(6, 'MD', 'Doctor of Medicine', 'MD', 48, 220.0);

-- 4. Terms (Academic Calendar)
INSERT INTO terms (code, name, term_type, academic_year, start_date, end_date, add_drop_date, grade_due_date, is_active) VALUES
('2026-AUTUMN', 'Autumn Quarter 2026', 'quarter', 2026, '2026-09-21', '2026-12-11', '2026-10-09', '2026-12-18', 1),
('2027-WINTER', 'Winter Quarter 2027', 'quarter', 2027, '2027-01-04', '2027-03-19', '2027-01-22', '2027-03-26', 0),
('2027-SPRING', 'Spring Quarter 2027', 'quarter', 2027, '2027-03-29', '2027-06-09', '2027-04-16', '2027-06-16', 0);

-- 5. Roles
INSERT INTO roles (name, description) VALUES
('Super Admin', 'Full administrative authorization across all university systems'),
('Dean', 'Executive dean over school curricula and budget approval'),
('Department Chair', 'Head of academic department and faculty workload supervisor'),
('Faculty', 'Professors, lecturers, and principal research investigators'),
('Student', 'Matriculated undergraduate, graduate, or professional student'),
('Staff', 'Registrar, financial controllers, lab managers, and campus staff');

-- 6. Core Users & Identities
INSERT INTO users (campus_id, sunet_id, name, email, password, phone) VALUES
(1, 'jhennessy', 'John Hennessy', 'hennessy@stanford.edu', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1-650-723-2300'),
(1, 'dknuth', 'Donald Knuth', 'knuth@cs.stanford.edu', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1-650-723-4321'),
(1, 'anng', 'Andrew Ng', 'ang@cs.stanford.edu', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1-650-725-1234'),
(1, 'feifeili', 'Fei-Fei Li', 'feifeili@cs.stanford.edu', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1-650-725-5678'),
(1, 'rahul_dg', 'Rahul Dasgupta', 'rahuldg@stanford.edu', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1-650-555-0199'),
(1, 'alex_chen', 'Alex Chen', 'alexchen@stanford.edu', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1-650-555-0144');

-- 7. Faculty & Staff Profiles
INSERT INTO faculty (user_id, department_id, office_room_id, hire_date, rank, tenured) VALUES
(1, 1, 3, '1977-09-01', 'Emeritus', 1),
(2, 1, 3, '1968-09-01', 'Emeritus', 1),
(3, 1, 3, '2002-09-01', 'Associate', 1),
(4, 1, 3, '2009-07-01', 'Full', 1);

-- 8. Students & Multi-Major Declarations
INSERT INTO students (user_id, student_number, program_id, catalog_year, enrollment_date, status) VALUES
(5, 'STU-00984123', 2, 2025, '2025-09-15', 'active'),
(6, 'STU-00984124', 1, 2024, '2024-09-16', 'active');

INSERT INTO student_programs (student_id, program_id, program_type, declared_at) VALUES
(1, 2, 'major', '2025-09-20'),
(2, 1, 'major', '2024-10-01'),
(2, 5, 'minor', '2025-01-15');

-- 9. Courses & Prerequisite DAG
INSERT INTO courses (department_id, code, title, credits, description) VALUES
(1, 'CS106A', 'Programming Methodology', 5.0, 'Introduction to the engineering of computer applications emphasizing modern software engineering principles.'),
(1, 'CS106B', 'Programming Abstractions', 5.0, 'Abstraction and its relation to programming. Software engineering principles of data abstraction and modularity.'),
(1, 'CS161', 'Design and Analysis of Algorithms', 4.0, 'Worst and average case analysis. Recurrences and asymptots. Divide and conquer, dynamic programming, and greedy algorithms.'),
(1, 'CS229', 'Machine Learning', 4.0, 'Broad introduction to machine learning, datamining, and statistical pattern recognition.');

INSERT INTO course_prerequisites (course_id, prerequisite_id, min_grade) VALUES
(2, 1, 'C'),   -- CS106B requires CS106A
(3, 2, 'C'),   -- CS161 requires CS106B
(4, 3, 'B-');  -- CS229 requires CS161

-- 10. Scheduled Sections, Instructors & Timetables
INSERT INTO sections (course_id, term_id, section_no, delivery_mode, max_capacity, waitlist_cap, enrolled_count) VALUES
(4, 1, '01', 'in_person', 150, 40, 148), -- CS229 Autumn 2026
(2, 1, '01', 'in_person', 200, 50, 190); -- CS106B Autumn 2026

INSERT INTO section_instructors (section_id, faculty_id, role, workload_pct) VALUES
(1, 3, 'primary_instructor', 100.00), -- Andrew Ng teaches CS229
(2, 4, 'primary_instructor', 100.00); -- Fei-Fei Li teaches CS106B

INSERT INTO class_schedules (section_id, room_id, day_of_week, start_time, end_time) VALUES
(1, 1, 'Mon', '09:30:00', '11:00:00'),
(1, 1, 'Wed', '09:30:00', '11:00:00'),
(2, 4, 'Tue', '13:30:00', '15:00:00'),
(2, 4, 'Thu', '13:30:00', '15:00:00');

-- 11. Enrollments & Grades
INSERT INTO enrollments (student_id, section_id, status) VALUES
(1, 1, 'enrolled'),
(2, 2, 'enrolled');

INSERT INTO grades (enrollment_id, grade, gpa_points, credits_earned, is_final, submitted_by) VALUES
(1, 'A+', 4.00, 4.0, 1, 3),
(2, 'A',  4.00, 5.0, 1, 4);

-- 12. Sponsored Research Lab & Grants
INSERT INTO research_labs (name, department_id, location, director_id, annual_budget) VALUES
('Stanford Artificial Intelligence Laboratory (SAIL)', 1, 'Gates Building 2nd Floor', 4, 15000000.00),
('Stanford Center for Automated Reasoning', 1, 'Gates Building 3rd Floor', 2, 8500000.00);

INSERT INTO research_grants (lab_id, grant_number, funding_agency, amount, start_date, end_date) VALUES
(1, 'NSF-IIS-2026-9041', 'National Science Foundation', 4500000.00, '2026-01-01', '2029-12-31'),
(1, 'DARPA-AI-NEXT-04', 'Defense Advanced Research Projects Agency', 6200000.00, '2026-06-01', '2030-05-31');

INSERT INTO publications (lab_id, title, journal, doi, published_at) VALUES
(1, 'Foundations of Deep Learning Representations for Multi-Agent Autonomy', 'Nature Machine Intelligence', '10.1038/s42256-026-00912-x', '2026-04-12');
