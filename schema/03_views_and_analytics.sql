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
