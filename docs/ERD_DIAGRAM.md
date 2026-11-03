# 📊 University Enterprise Entity-Relationship Diagrams (ERD)

This document provides visual architectural representations of the core relational clusters within the Tier-1 University Management Database.

---

## 🎓 1. Academic & Curricular Architecture

```mermaid
erDiagram
    DEPARTMENTS ||--o{ DEGREE_PROGRAMS : offers
    DEPARTMENTS ||--o{ COURSES : owns
    DEGREE_PROGRAMS ||--o{ DEGREE_REQUIREMENTS : specifies
    DEGREE_PROGRAMS ||--o{ STUDENTS : matriculates
    STUDENTS ||--o{ STUDENT_PROGRAMS : declares
    DEGREE_PROGRAMS ||--o{ STUDENT_PROGRAMS : enrolled_in
    
    COURSES ||--o{ COURSE_PREREQUISITES : requires
    COURSES ||--o{ COURSE_EQUIVALENCIES : equivalent_to
    COURSES ||--o{ SECTIONS : schedules
    TERMS ||--o{ SECTIONS : offers_during
    
    SECTIONS ||--o{ SECTION_INSTRUCTORS : taught_by
    FACULTY ||--o{ SECTION_INSTRUCTORS : assigned_to
    SECTIONS ||--o{ CLASS_SCHEDULES : timetabled_at
    ROOMS ||--o{ CLASS_SCHEDULES : held_in
    
    SECTIONS ||--o{ ENROLLMENTS : registers
    STUDENTS ||--o{ ENROLLMENTS : attends
    SECTIONS ||--o{ COURSE_WAITLISTS : queues
    STUDENTS ||--o{ COURSE_WAITLISTS : waiting_on
    
    ENROLLMENTS ||--o| GRADES : evaluated_as
    ENROLLMENTS ||--o{ ASSIGNMENT_GRADES : scores
    GRADES ||--o{ GRADE_CHANGE_LOGS : audited_by
```

---

## 🏛️ 2. Core Identity, Facilities & Research Cluster

```mermaid
erDiagram
    CAMPUSES ||--o{ BUILDINGS : contains
    CAMPUSES ||--o{ DEPARTMENTS : houses
    CAMPUSES ||--o{ USERS : based_at
    BUILDINGS ||--o{ ROOMS : divides_into
    ROOMS ||--o{ EQUIPMENT : stores
    EQUIPMENT ||--o{ MAINTENANCE_LOGS : requires
    
    USERS ||--o{ USER_ROLES : has
    ROLES ||--o{ USER_ROLES : assigned_to
    USERS ||--o| STUDENTS : role_profile
    USERS ||--o| FACULTY : role_profile
    USERS ||--o| STAFF : role_profile
    
    DEPARTMENTS ||--o{ RESEARCH_LABS : manages
    FACULTY ||--o{ RESEARCH_LABS : directs
    RESEARCH_LABS ||--o{ RESEARCH_GRANTS : funded_by
    RESEARCH_LABS ||--o{ LAB_MEMBERSHIPS : employs
    USERS ||--o{ LAB_MEMBERSHIPS : participates_in
    RESEARCH_LABS ||--o{ PUBLICATIONS : authors
    
    PATENT_RECORDS ||--o{ RESEARCH_INVENTIONS : shares
    USERS ||--o{ RESEARCH_INVENTIONS : invented_by
```

---

## 💰 3. Financial Ledger & Student Accounts

```mermaid
erDiagram
    STUDENTS ||--o{ INVOICES : billed_to
    TERMS ||--o{ INVOICES : for_term
    STUDENTS ||--o{ PAYMENTS : remits
    INVOICES ||--o{ PAYMENTS : settles
    STUDENTS ||--o{ FINANCIAL_AID : awarded
    STUDENTS ||--o{ SCHOLARSHIPS : receives
    STAFF ||--o{ PAYROLL : compensated
```
