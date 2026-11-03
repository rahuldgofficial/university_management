# 📖 University Enterprise Database Data Dictionary

This document provides a comprehensive technical reference for the Tier-1 University Enterprise Database Schema.

---

## 🏛️ 1. Campuses & Facilities

| Table | Primary Key | Key Foreign Keys | Purpose & Business Rules |
| :--- | :--- | :--- | :--- |
| `campuses` | `id (SMALLINT UNSIGNED)` | None | Physical campus branches. Supports localized timezone anchors for multi-region campuses. |
| `buildings` | `id (BIGINT UNSIGNED)` | `campus_id -> campuses(id)` | Infrastructure complexes. Enforces unique building code per campus (`uq_building_campus`). |
| `rooms` | `id (BIGINT UNSIGNED)` | `building_id -> buildings(id)` | Instruction and office spaces. Tracks physical capacity, ADA accessibility, and A/V equipment. |

---

## 🎓 2. Academic Governance & Curricula

| Table | Primary Key | Key Foreign Keys | Purpose & Business Rules |
| :--- | :--- | :--- | :--- |
| `departments` | `id (BIGINT UNSIGNED)` | `campus_id -> campuses(id)` | Academic units (e.g. CS, EE, Bioengineering). Enforces unique department code per campus. |
| `degree_programs` | `id (BIGINT UNSIGNED)` | `department_id -> departments(id)` | Degree pathways (BSc, BA, MSc, PhD, MD, JD). Tracks duration in months and required graduation credits. |
| `degree_requirements` | `id (BIGINT UNSIGNED)` | `program_id -> degree_programs(id)` | Curricular graduation milestones, minimum GPA requirements, and capstone criteria. |
| `terms` | `id (BIGINT UNSIGNED)` | None | Academic quarters and semesters. Validates `CHECK (end_date > start_date)`. Contains add/drop and grading deadlines. |

---

## 👤 3. Core Identity & Multi-Role Person Registry

| Table | Primary Key | Key Foreign Keys | Purpose & Business Rules |
| :--- | :--- | :--- | :--- |
| `users` | `id (BIGINT UNSIGNED)` | `campus_id -> campuses(id)` | Central identity table. Incorporates Stanford-standard `sunet_id` (SSO identifier), FERPA directory privacy block, and bcrypt passwords. |
| `roles` | `id (TINYINT UNSIGNED)` | None | RBAC definitions (Super Admin, Dean, Department Chair, Faculty, Student, Staff). |
| `user_roles` | `(user_id, role_id)` | `user_id -> users(id)`, `role_id -> roles(id)` | Many-to-many role junction with delegating administrator tracking (`created_by`). |
| `students` | `id (BIGINT UNSIGNED)` | `user_id -> users(id)`, `program_id -> degree_programs(id)` | Matriculated student registry. Tracks student identification number, catalog year, and enrollment standing. |
| `student_programs` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `program_id -> degree_programs(id)` | Multi-program declarations (double majors, minors, coterminal degrees). |
| `faculty` | `id (BIGINT UNSIGNED)` | `user_id -> users(id)`, `department_id -> departments(id)`, `office_room_id -> rooms(id)` | Professorial appointments. Tracks rank, tenured status, tenure date, and office allocations. |
| `staff` | `id (BIGINT UNSIGNED)` | `user_id -> users(id)`, `department_id -> departments(id)`, `supervisor_id -> staff(id)` | Operational personnel with hierarchical supervisor tree. |

---

## 📚 4. Course Catalog & Schedule Engine

| Table | Primary Key | Key Foreign Keys | Purpose & Business Rules |
| :--- | :--- | :--- | :--- |
| `courses` | `id (BIGINT UNSIGNED)` | `department_id -> departments(id)` | Course catalog. Enforces unique course codes within departments. Includes repeatable and grading options. |
| `course_prerequisites` | `(course_id, prerequisite_id)` | `course_id -> courses(id)`, `prerequisite_id -> courses(id)` | Directed acyclic graph (DAG) enforcing prerequisite sequences and minimum prerequisite letter grades. |
| `course_equivalencies` | `id (BIGINT UNSIGNED)` | `course_id -> courses(id)`, `equivalent_id -> courses(id)` | Cross-listed and transfer course equivalencies (e.g. CS229 / STATS229). |
| `sections` | `id (BIGINT UNSIGNED)` | `course_id -> courses(id)`, `term_id -> terms(id)` | Term-specific scheduled class sections with hard capacity gates and waitlist boundaries. |
| `section_instructors` | `id (BIGINT UNSIGNED)` | `section_id -> sections(id)`, `faculty_id -> faculty(id)` | Multi-instructor sections with role categorization (Primary, Co-Instructor, TA) and workload percentages. |
| `class_schedules` | `id (BIGINT UNSIGNED)` | `section_id -> sections(id)`, `room_id -> rooms(id)` | Room timetable reservations. Backed by `CHECK (end_time > start_time)` and composite conflict indexes. |
| `enrollments` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `section_id -> sections(id)` | Enrolled, waitlisted, dropped, and completed class enrollments. |
| `course_waitlists` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `section_id -> sections(id)` | FIFO priority queue for over-subscribed sections with time-sensitive offer expirations. |

---

## 📝 5. Academic Grading & Transcript Engine

| Table | Primary Key | Key Foreign Keys | Purpose & Business Rules |
| :--- | :--- | :--- | :--- |
| `grade_scale` | `id (TINYINT UNSIGNED)` | None | University grade conversion scale (A+=4.0, A=4.0, A-=3.7, etc.). |
| `assignment_grades` | `id (BIGINT UNSIGNED)` | `enrollment_id -> enrollments(id)` | Itemized assessments (homework, exams, capstones) with weighted score calculation. |
| `grades` | `id (BIGINT UNSIGNED)` | `enrollment_id -> enrollments(id)` | Official term grade and GPA credit point assignment. Linked to submitting faculty. |
| `grade_change_logs` | `id (BIGINT UNSIGNED)` | `grade_id -> grades(id)`, `changed_by -> users(id)` | Mandatory FERPA grade modification audit trail capturing previous and revised grades with justifications. |
| `transcripts` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `term_id -> terms(id)` | Immutable historical transcript snapshots accompanied by SHA-256 verification hashes. |
| `academic_warnings` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `term_id -> terms(id)` | Academic probation, low GPA warnings, and dishonesty incident tracking. |

---

## 💰 6. Financial Ledger & Tuition Billing

| Table | Primary Key | Key Foreign Keys | Purpose & Business Rules |
| :--- | :--- | :--- | :--- |
| `tuition_fees` | `id (BIGINT UNSIGNED)` | `program_id -> degree_programs(id)`, `term_id -> terms(id)` | Tuition rate structures per degree program and academic term. |
| `invoices` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `term_id -> terms(id)` | Student financial statements with itemized billing and due dates. |
| `payments` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `invoice_id -> invoices(id)` | Disbursed student payments via credit card, wire, check, or bank transfer. |
| `financial_aid` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `renewal_term -> terms(id)` | Need-based and merit-based institutional financial aid packages. |
| `scholarships` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)`, `renewal_term_id -> terms(id)` | Endowed and departmental scholarship awards. |
| `payroll` | `id (BIGINT UNSIGNED)` | `staff_id -> staff(id)` | Staff and student worker payroll records with gross, net, and itemized JSON deductions. |
| `endowment_funds` | `id (BIGINT UNSIGNED)` | None | Multimillion-dollar university endowment funds and annual spending limits. |

---

## 🔬 7. Sponsored Research & Technology Transfer

| Table | Primary Key | Key Foreign Keys | Purpose & Business Rules |
| :--- | :--- | :--- | :--- |
| `research_labs` | `id (BIGINT UNSIGNED)` | `department_id -> departments(id)`, `director_id -> faculty(id)` | Autonomous research laboratories with allocated annual operating budgets. |
| `research_grants` | `id (BIGINT UNSIGNED)` | `lab_id -> research_labs(id)` | External federal (NSF, DARPA, NIH) and private corporate grant allocations. |
| `lab_memberships` | `id (BIGINT UNSIGNED)` | `lab_id -> research_labs(id)`, `user_id -> users(id)` | Principal investigators, postdocs, and graduate research assistants. |
| `publications` | `id (BIGINT UNSIGNED)` | `lab_id -> research_labs(id)` | Scholarly research publications, peer-reviewed journals, and DOI citations. |
| `patent_records` | `id (BIGINT UNSIGNED)` | None | Intellectual property filings, patent numbers, and technology commercialization licensing status. |
| `research_inventions` | `id (BIGINT UNSIGNED)` | `patent_id -> patent_records(id)`, `inventor_id -> users(id)` | Royalty share and percentage contribution per university inventor. |

---

## 🛡️ 8. Enterprise Governance, Health & Safety

| Table | Primary Key | Key Foreign Keys | Purpose & Business Rules |
| :--- | :--- | :--- | :--- |
| `audit_logs` | `id (BIGINT UNSIGNED)` | `user_id -> users(id)` | Complete forensic audit trail of all schema mutations, capturing before/after JSON states and IP address. |
| `health_records` | `id (BIGINT UNSIGNED)` | `user_id -> users(id)` | Encrypted student health, immunization, and medical visit records protected by HIPAA/FERPA standards. |
| `incident_reports` | `id (BIGINT UNSIGNED)` | `reporter_id -> users(id)` | Campus police and security incident reporting with investigation status tracking. |
| `visa_records` | `id (BIGINT UNSIGNED)` | `student_id -> students(id)` | International student SEVIS and I-20 visa compliance tracking. |
