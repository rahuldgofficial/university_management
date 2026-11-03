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
