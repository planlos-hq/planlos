-- Fictional test data for a fresh PlanLos database (schema version 7), loaded by testdata.sh.
-- All names are made up. 6 degree programs with 3 cohorts each (1st, 3rd and 5th semester),
-- 5 courses per cohort with 2 weekly slots, 36 lecturers, 20 rooms.
-- The timetable is generated without clashes: cohorts of the same semester run in parallel
-- (each program in its own rooms), semesters are staggered, a lecturer teaches the same
-- course position in all semesters of one program.
-- Deliberate problems to try the checks:
--   room and study group conflict  ET-105 extra slot on Monday 08:00 in A1.03 (with ET-101)
--   soft lecturer constraint       Mustermann (INF-101) not on Monday morning
--   hard lecturer constraint       Fischer (WIF-102) not on Tuesday 08:00-09:00
--   lab engineers only             MB-306 Laborkolloquium
-- Also a one-off Saturday block seminar for INF-505 on 2025-11-15.
-- Weekdays as in JavaScript: 0 = Sunday, 1 = Monday ... 6 = Saturday.
\set ON_ERROR_STOP on

begin;

do $$
begin
    if exists (select from room) or exists (select from lecturer) or exists (select from course) then
        raise exception 'Datenbank enthält bereits Daten, Testdaten werden nicht eingefügt';
    end if;
end
$$;

-- Degree programs: p = position, students = 1st semester size, lab = name of its lab
create temporary table program (p int, name text, abbreviation text, students int, lab text) on commit drop;

insert into program
    values (0, 'Informatik', 'INF', 70, 'Rechnerlabor'), (1, 'Wirtschaftsinformatik', 'WIF', 45, 'Wirtschaftslabor'), (2, 'Elektrotechnik', 'ET', 35, 'Elektroniklabor'), (3, 'Maschinenbau', 'MB', 50, 'Werkstofflabor'), (4, 'Medieninformatik', 'MI', 55, 'Medienlabor'), (5, 'Wirtschaftsingenieurwesen', 'WIW', 40, 'Planspiellabor');

insert into degree_program (name, abbreviation)
select
    name, abbreviation
from
    program
order by
    p;

-- Cohorts: r = 0, 1, 2 for the 1st, 3rd and 5th semester
insert into study_group (semester_season, semester_year, student_count, degree_program)
select
    'winter', 2025 - r, round(pr.students * (array[1, 0.8, 0.65])[r + 1]), dp.id
from
    program pr
    cross join generate_series(0, 2) r
    join degree_program dp on dp.abbreviation = pr.abbreviation
order by
    pr.p, r;

-- Rooms: per program a lecture room (A1.0x) and a lab (L2.0x) big enough for its cohorts, plus some unused ones
insert into room (number, name, seats)
select
    'A1.0' || p + 1, 'Hörsaal ' || p + 1, students + 20
from
    program
union all
select
    'L2.0' || p + 1, lab, students + 10
from
    program
union all
select
    *
from (values ('C0.01', 'Seminarraum 1', 30), ('C0.02', 'Seminarraum 2', 30), ('C0.03', 'Besprechungsraum', 12), ('B1.01', 'Rechnerpool 1', 40), ('B1.02', 'Rechnerpool 2', 40), ('D0.01', 'Großer Hörsaal', 200), ('D0.02', 'Kleiner Hörsaal', 80), ('E0.01', 'Aula', 300)) v;

-- Courses: c = position in the cohort, 0-2 lectures, 3 lab, 4 seminar
create temporary table course_def on commit drop as
select
    pr.p, v.r, v.c, v.program || '-' || v.r * 2 + 1 || lpad((v.c + 1)::text, 2, '0') as number, v.name, v.abbreviation
from (values
        ('INF', 0, 0, 'Programmierung 1', 'PR1'), ('INF', 0, 1, 'Mathematik 1', 'MA1'), ('INF', 0, 2, 'Rechnerarchitektur', 'RA'), ('INF', 0, 3, 'Grundlagenpraktikum Programmierung', 'GPP'), ('INF', 0, 4, 'Wissenschaftliches Arbeiten', 'WA'),
        ('INF', 1, 0, 'Algorithmen und Datenstrukturen', 'ADS'), ('INF', 1, 1, 'Datenbanken', 'DB'), ('INF', 1, 2, 'Betriebssysteme', 'BS'), ('INF', 1, 3, 'Praktikum Datenbanken', 'PDB'), ('INF', 1, 4, 'Seminar Informatik und Gesellschaft', 'IUG'),
        ('INF', 2, 0, 'Softwaretechnik', 'SWT'), ('INF', 2, 1, 'Rechnernetze', 'RN'), ('INF', 2, 2, 'IT-Sicherheit', 'ITS'), ('INF', 2, 3, 'Softwareprojekt', 'SWP'), ('INF', 2, 4, 'Seminar Künstliche Intelligenz', 'SKI'),
        ('WIF', 0, 0, 'Grundlagen BWL', 'BWL'), ('WIF', 0, 1, 'Programmierung für Wirtschaftsinformatik', 'PWI'), ('WIF', 0, 2, 'Mathematik für Wirtschaft', 'MAW'), ('WIF', 0, 3, 'Praktikum Tabellenkalkulation', 'PTK'), ('WIF', 0, 4, 'Präsentationstechniken', 'PT'),
        ('WIF', 1, 0, 'Geschäftsprozessmanagement', 'GPM'), ('WIF', 1, 1, 'Rechnungswesen', 'RW'), ('WIF', 1, 2, 'Informationssysteme', 'IS'), ('WIF', 1, 3, 'Praktikum ERP-Systeme', 'ERP'), ('WIF', 1, 4, 'Seminar Digitale Transformation', 'SDT'),
        ('WIF', 2, 0, 'IT-Controlling', 'ITC'), ('WIF', 2, 1, 'E-Business', 'EB'), ('WIF', 2, 2, 'Projektmanagement', 'PM'), ('WIF', 2, 3, 'Praktikum Business Intelligence', 'PBI'), ('WIF', 2, 4, 'Seminar Wirtschaftsrecht', 'SWR'),
        ('ET', 0, 0, 'Grundlagen der Elektrotechnik 1', 'GET1'), ('ET', 0, 1, 'Mathematik 1 für Ingenieure', 'MI1'), ('ET', 0, 2, 'Physik', 'PH'), ('ET', 0, 3, 'Elektronikpraktikum', 'EPR'), ('ET', 0, 4, 'Technisches Englisch', 'TE'),
        ('ET', 1, 0, 'Grundlagen der Elektrotechnik 2', 'GET2'), ('ET', 1, 1, 'Messtechnik', 'MT'), ('ET', 1, 2, 'Digitaltechnik', 'DT'), ('ET', 1, 3, 'Praktikum Messtechnik', 'PMT'), ('ET', 1, 4, 'Seminar Energiewende', 'SEW'),
        ('ET', 2, 0, 'Regelungstechnik', 'RT'), ('ET', 2, 1, 'Leistungselektronik', 'LE'), ('ET', 2, 2, 'Nachrichtentechnik', 'NT'), ('ET', 2, 3, 'Praktikum Mikrocontroller', 'PMC'), ('ET', 2, 4, 'Seminar Elektromobilität', 'SEM'),
        ('MB', 0, 0, 'Technische Mechanik 1', 'TM1'), ('MB', 0, 1, 'Werkstoffkunde', 'WK'), ('MB', 0, 2, 'Konstruktionslehre 1', 'KL1'), ('MB', 0, 3, 'CAD-Praktikum', 'CAD'), ('MB', 0, 4, 'Kommunikation im Ingenieurberuf', 'KIB'),
        ('MB', 1, 0, 'Technische Mechanik 2', 'TM2'), ('MB', 1, 1, 'Thermodynamik', 'TD'), ('MB', 1, 2, 'Fertigungstechnik', 'FT'), ('MB', 1, 3, 'Werkstoffpraktikum', 'WKP'), ('MB', 1, 4, 'Seminar Nachhaltige Produktion', 'SNP'),
        ('MB', 2, 0, 'Strömungslehre', 'SL'), ('MB', 2, 1, 'Maschinenelemente', 'ME'), ('MB', 2, 2, 'Finite-Elemente-Methode', 'FEM'), ('MB', 2, 3, 'Praktikum Fertigung', 'PF'), ('MB', 2, 4, 'Seminar Industrie 4.0', 'SI4'),
        ('MI', 0, 0, 'Grundlagen der Programmierung', 'GP'), ('MI', 0, 1, 'Mediengestaltung', 'MG'), ('MI', 0, 2, 'Mathematik für Medieninformatik', 'MMI'), ('MI', 0, 3, 'Praktikum Webtechnologien', 'PWT'), ('MI', 0, 4, 'Medienrecht', 'MR'),
        ('MI', 1, 0, 'Computergrafik', 'CG'), ('MI', 1, 1, 'Mensch-Computer-Interaktion', 'MCI'), ('MI', 1, 2, 'Webentwicklung', 'WE'), ('MI', 1, 3, 'Praktikum Audio und Video', 'PAV'), ('MI', 1, 4, 'Seminar Usability', 'SUS'),
        ('MI', 2, 0, 'Game Design', 'GD'), ('MI', 2, 1, 'Mobile Anwendungen', 'MOA'), ('MI', 2, 2, 'Visualisierung', 'VIS'), ('MI', 2, 3, 'Medienprojekt', 'MPJ'), ('MI', 2, 4, 'Seminar Virtual Reality', 'SVR'),
        ('WIW', 0, 0, 'Einführung Wirtschaftsingenieurwesen', 'EWI'), ('WIW', 0, 1, 'Technische Mechanik für WIW', 'TMW'), ('WIW', 0, 2, 'Mikroökonomie', 'MIK'), ('WIW', 0, 3, 'Praktikum Werkstoffe', 'PWS'), ('WIW', 0, 4, 'Wissenschaftliches Arbeiten', 'WAW'),
        ('WIW', 1, 0, 'Produktionswirtschaft', 'PW'), ('WIW', 1, 1, 'Logistik', 'LOG'), ('WIW', 1, 2, 'Elektrotechnik für WIW', 'ETW'), ('WIW', 1, 3, 'Planspiel Unternehmensführung', 'PUF'), ('WIW', 1, 4, 'Seminar Qualitätsmanagement', 'SQM'),
        ('WIW', 2, 0, 'Supply Chain Management', 'SCM'), ('WIW', 2, 1, 'Investition und Finanzierung', 'IUF'), ('WIW', 2, 2, 'Operations Research', 'OR'), ('WIW', 2, 3, 'Fallstudienprojekt', 'FSP'), ('WIW', 2, 4, 'Seminar Technologiemanagement', 'STM'),
        -- Extra, outside the generated timetable
        ('MB', 1, 5, 'Laborkolloquium', 'LK')) v (program, r, c, name, abbreviation)
    join program pr on pr.abbreviation = v.program;

insert into course (number, name, sws, credit_points, abbreviation)
select
    number, name, case when c = 0 then 6 when c < 3 then 4 else 2 end, case when c = 0 then 8 when c < 3 then 5 else 3 end, abbreviation
from
    course_def
order by
    p, r, c;

insert into course_color (name, hex)
    values ('Vorlesung', '#4A90D9'), ('Übung', '#50B36B'), ('Praktikum', '#E5A23C'), ('Seminar', '#9B6BD1');

-- First course of each cohort is a lecture with exercise, so it gets two colours
insert into course_color_assignment (course, color)
select
    co.id, cc.id
from
    course_def cd
    join course co on co.number = cd.number
    join course_color cc on cc.name = case when cd.c in (3, 5) then 'Praktikum' when cd.c = 4 then 'Seminar' else 'Vorlesung' end
        or (cd.c = 0 and cc.name = 'Übung');

insert into course_study_group (course, study_group)
select
    co.id, sg.id
from
    course_def cd
    join course co on co.number = cd.number
    join program pr on pr.p = cd.p
    join degree_program dp on dp.abbreviation = pr.abbreviation
    join study_group sg on sg.degree_program = dp.id
        and sg.semester_year = 2025 - cd.r;

-- Lecturers: i < 30 teaches course position c = i % 5 in program p = i / 5, i >= 30 are the lab engineers of program i - 30
create temporary table lecturer_def on commit drop as
select
    i, case when i < 30 then i / 5 else i - 30 end as p, case when i < 30 then i % 5 end as c,
    (array['Erika', 'Max', 'Anna', 'Jonas', 'Lena', 'Paul', 'Sophie', 'Felix', 'Marie', 'Lukas', 'Laura', 'Tim', 'Julia', 'David', 'Sarah', 'Simon', 'Lisa', 'Jan', 'Hannah', 'Moritz', 'Clara', 'Niklas', 'Emma', 'Philipp', 'Mia', 'Tobias', 'Lea', 'Florian', 'Nina', 'Sebastian', 'Johanna', 'Daniel', 'Katharina', 'Fabian', 'Theresa', 'Benedikt'])[i + 1] as first_name,
    (array['Mustermann', 'Beispiel', 'Probe', 'Weber', 'Schneider', 'Muster', 'Fischer', 'Wagner', 'Becker', 'Schulz', 'Hoffmann', 'Koch', 'Klein', 'Wolf', 'Schröder', 'Neumann', 'Schwarz', 'Zimmermann', 'Braun', 'Krüger', 'Hartmann', 'Lange', 'Werner', 'Krause', 'Lehmann', 'Köhler', 'Herrmann', 'König', 'Walter', 'Peters', 'Möller', 'Kaiser', 'Fuchs', 'Jung', 'Vogel', 'Roth'])[i + 1] as last_name,
    case when i >= 30 then 'lab_engineer' when i % 5 = 4 then 'adjunct_professor' else 'regular' end as kind
from
    generate_series(0, 35) i;

insert into lecturer (title, first_name, last_name, abbreviation, kind)
select
    case kind when 'regular' then 'Prof. Dr.' when 'adjunct_professor' then 'Dr.' end, first_name, last_name, upper(left(first_name, 1) || left(last_name, 2)), kind
from
    lecturer_def
order by
    i;

-- Course position c of the program, labs (c = 3) additionally the program's lab engineer, MB-306 only that one
insert into course_lecturer (course, lecturer)
select
    co.id, l.id
from
    course_def cd
    join course co on co.number = cd.number
    join lecturer_def ld on ld.p = cd.p
        and (ld.c = cd.c or (ld.i >= 30 and cd.c in (3, 5)))
    join lecturer l on l.first_name = ld.first_name
        and l.last_name = ld.last_name;

-- Constraints: Saturdays off and no evenings, both outside all slots, plus the two deliberate violations
insert into lecturer_negative_time_constraint (lecturer, weekday, at, duration, soft)
select
    l.id, v.weekday, v.at, v.duration, v.soft
from
    lecturer_def ld
    join lecturer l on l.first_name = ld.first_name
        and l.last_name = ld.last_name
    cross join lateral (
        select 6, time '08:00', interval '12 hours', false where ld.i % 3 = 2
        union all
        select d, time '18:30', interval '3 hours', true from generate_series(1, 5) d where ld.i % 4 = 3
        union all
        select 1, time '08:00', interval '1:30', true where ld.i = 0
        union all
        select 2, time '08:00', interval '1 hour', false where ld.i = 6) v (weekday, at, duration, soft);

-- Time slots: 30 blocks per week (Monday-Friday, 6 per day). Course c of cohort r uses blocks
-- (2c + s) * 3 + r for its slots s = 0, 1, so cohorts never clash and semesters are staggered.
create temporary table slot on commit drop as
select
    cd.number, (b / 6 + 1)::smallint as weekday, (array['08:00', '09:45', '11:30', '13:30', '15:15', '17:00'])[b % 6 + 1]::time as at, interval '1:30' as duration, null::date as one_off_date, case when cd.c = 3 then 'L2.0' else 'A1.0' end || cd.p + 1 as room
from
    course_def cd
    cross join generate_series(0, 1) s
    cross join lateral (
        select (2 * cd.c + s) * 3 + cd.r as b) x
where
    cd.c <= 4;

insert into slot
    values ('ET-105', 1, '08:00', '1:30', null, 'A1.03'), ('MB-306', 1, '08:00', '1:30', null, 'L2.04'), ('INF-505', 6, '09:00', '6:00', '2025-11-15', 'D0.02');

insert into course_time_slots (course, weekday, at, duration, one_off_date)
select
    co.id, s.weekday, s.at, s.duration, s.one_off_date
from
    slot s
    join course co on co.number = s.number
order by
    co.id, s.weekday, s.at;

insert into time_slot_room_assignment (time_slot, room)
select
    cts.id, r.id
from
    slot s
    join course co on co.number = s.number
    join course_time_slots cts on cts.course = co.id
        and cts.weekday = s.weekday
        and cts.at = s.at
        and cts.one_off_date is not distinct from s.one_off_date
    join room r on r.number = s.room;

-- Templates: 1st semester courses of each program
insert into study_group_template (name)
select
    name || ' 1. Semester'
from
    program
order by
    p;

insert into study_group_template_course (template, course)
select
    t.id, co.id
from
    course_def cd
    join program pr on pr.p = cd.p
    join study_group_template t on t.name = pr.name || ' 1. Semester'
    join course co on co.number = cd.number
where
    cd.r = 0;

commit;
