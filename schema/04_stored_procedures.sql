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
