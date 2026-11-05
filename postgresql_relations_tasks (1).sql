-- Очистка (на случай повторного запуска)
DROP VIEW IF EXISTS employee_access_cards;
DROP VIEW IF EXISTS department_employees;
DROP VIEW IF EXISTS student_courses;
DROP VIEW IF EXISTS rental_details;

DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS rentals;
DROP TABLE IF EXISTS access_cards;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS bicycles;
DROP TABLE IF EXISTS rental_points;


--задание 1. Сотрудники и пропуска — связь один-к-одному


-- 1. Создаём таблицы
CREATE TABLE employees (
    employee_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name    VARCHAR(100) NOT NULL,
    position     VARCHAR(50),
    hire_date    DATE DEFAULT CURRENT_DATE
);

CREATE TABLE access_cards (
    card_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    card_number  VARCHAR(20) NOT NULL UNIQUE,
    issue_date   DATE DEFAULT CURRENT_DATE,
    employee_id  INTEGER NOT NULL UNIQUE,          -- UNIQUE + NOT NULL = 1:1
    CONSTRAINT fk_access_cards_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees (employee_id)
        ON DELETE RESTRICT
);

-- 2. Связь настроена:
--UNIQUE на access_cards.employee_id -> одному сотруднику нельзя выдать несколько пропусков
--PRIMARY KEY / UNIQUE на card_id -> один пропуск нельзя закрепить за несколькими
--NOT NULL на employee_id  -> пропуск нельзя создать без сотрудника
--сотрудник может временно не иметь пропуска (нет обязательной обратной ссылки)

-- 3. Тестовые данные
INSERT INTO employees (full_name, position) VALUES
    ('Иванов Иван Иванович', 'Инженер'),
    ('Петрова Анна Сергеевна', 'Бухгалтер'),
    ('Сидоров Алексей Петрович', 'Менеджер'),
    ('Козлова Мария Викторовна', 'Администратор');  -- без пропуска

INSERT INTO access_cards (card_number, employee_id) VALUES
    ('AC-001', 1),
    ('AC-002', 2),
    ('AC-003', 3);

-- 4. JOIN: имя сотрудника и номер пропуска
SELECT e.full_name, ac.card_number
FROM employees e
INNER JOIN access_cards ac ON e.employee_id = ac.employee_id
ORDER BY e.employee_id;

-- 5. Представление
CREATE VIEW employee_access_cards AS
SELECT e.employee_id,
       e.full_name,
       e.position,
       ac.card_number,
       ac.issue_date
FROM employees e
INNER JOIN access_cards ac ON e.employee_id = ac.employee_id;

SELECT * FROM employee_access_cards;

-- 6. Проверка ограничений
-- Попытка выдать второму пропуску одному сотруднику (должна упасть)
-- INSERT INTO access_cards (card_number, employee_id) VALUES ('AC-999', 1);
-- Ошибка: duplicate key value violates unique constraint
-- Попытка создать пропуск без сотрудника (должна упасть)
-- INSERT INTO access_cards (card_number, employee_id) VALUES ('AC-000', NULL);
-- Ошибка: null value in column "employee_id" violates not-null constraint


-- 2. Отделы и сотрудники — связь один-ко-многим

-- Пересоздаём employees (в задании 1 она уже была, поэтому сначала удаляем зависимые)
DROP VIEW IF EXISTS employee_access_cards;
DROP TABLE IF EXISTS access_cards;
DROP TABLE IF EXISTS employees;

CREATE TABLE departments (
    department_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    location        VARCHAR(100)
);

CREATE TABLE employees (
    employee_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    position        VARCHAR(50),
    hire_date       DATE DEFAULT CURRENT_DATE,
    department_id   INTEGER NOT NULL,
    CONSTRAINT fk_employees_department
        FOREIGN KEY (department_id)
        REFERENCES departments (department_id)
        ON DELETE RESTRICT          -- нельзя удалить отдел, в котором есть сотрудники
);

-- 3. Тестовые данные
INSERT INTO departments (name, location) VALUES
    ('IT', 'Офис А, 3 этаж'),
    ('Бухгалтерия', 'Офис Б, 2 этаж'),
    ('HR', 'Офис А, 1 этаж'),
    ('Маркетинг', 'Офис В, 4 этаж');

INSERT INTO employees (full_name, position, department_id) VALUES
    ('Иванов Иван Иванович', 'Разработчик', 1),
    ('Петрова Анна Сергеевна', 'Бухгалтер', 2),
    ('Сидоров Алексей Петрович', 'HR-менеджер', 3),
    ('Козлова Мария Викторовна', 'Аналитик', 1),
    ('Смирнов Дмитрий Олегович', 'Маркетолог', 4),
    ('Васильева Елена Ивановна', 'Тестировщик', 1);

-- 4. JOIN: сотрудники с названиями отделов
SELECT e.full_name, e.position, d.name AS department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
ORDER BY d.name, e.full_name;

-- 5. Представление
CREATE VIEW department_employees AS
SELECT e.employee_id,
       e.full_name,
       e.position,
       d.department_id,
       d.name AS department_name,
       d.location
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

SELECT * FROM department_employees;

-- 6. Сотрудники одного отдела (по названию)
SELECT e.full_name, e.position
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE d.name = 'IT';

-- или по идентификатору
SELECT full_name, position
FROM employees
WHERE department_id = 1;

-- 7. Перевод сотрудника в другой отдел
UPDATE employees
SET department_id = 4
WHERE full_name = 'Козлова Мария Викторовна';

-- Проверка
SELECT e.full_name, d.name AS department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE e.full_name = 'Козлова Мария Викторовна';

-- 8. Проверка ограничений
-- Несуществующий отдел (должна упасть)
-- INSERT INTO employees (full_name, position, department_id)
-- VALUES ('Тестовый Сотрудник', 'Стажёр', 999);
-- Ошибка: insert or update on table "employees" violates foreign key constraint
-- Удаление отдела, на который ссылаются сотрудники (должна упасть)
-- DELETE FROM departments WHERE name = 'IT';
-- Ошибка: update or delete on table "departments" violates foreign key constraint


-- 3. Студенты и курсы — связь многие-ко-многим

CREATE TABLE students (
    student_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    group_name  VARCHAR(20)
);

CREATE TABLE courses (
    course_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       VARCHAR(150) NOT NULL,
    hours       INTEGER CHECK (hours > 0),
    teacher     VARCHAR(100)
);

CREATE TABLE enrollments (
    enrollment_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id      INTEGER NOT NULL,
    course_id       INTEGER NOT NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status          VARCHAR(20) DEFAULT 'active'
                    CHECK (status IN ('active', 'completed', 'dropped')),
    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id) REFERENCES students (student_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id)
        ON DELETE RESTRICT,
    -- запрет повторной записи одного студента на один и тот же курс
    CONSTRAINT uq_student_course UNIQUE (student_id, course_id)
);

-- 3. Тестовые данные
INSERT INTO students (full_name, email, group_name) VALUES
    ('Алексеев Артём', 'artem@example.com', 'ИС-21'),
    ('Борисова Виктория', 'viktoria@example.com', 'ИС-21'),
    ('Григорьев Кирилл', 'kirill@example.com', 'ПИ-22'),
    ('Дмитриева Ольга', 'olga@example.com', 'ПИ-22'),
    ('Егоров Максим', 'maxim@example.com', 'ИС-21');

INSERT INTO courses (title, hours, teacher) VALUES
    ('Базы данных', 72, 'Иванова Н.П.'),
    ('Веб-разработка', 90, 'Петров С.А.'),
    ('Алгоритмы и структуры данных', 64, 'Сидорова Е.В.'),
    ('Машинное обучение', 80, 'Козлов Д.И.');

INSERT INTO enrollments (student_id, course_id, status) VALUES
    (1, 1, 'active'),
    (1, 2, 'active'),
    (2, 1, 'active'),
    (2, 3, 'completed'),
    (3, 2, 'active'),
    (3, 4, 'active'),
    (4, 1, 'dropped'),
    (5, 3, 'active'),
    (5, 4, 'active');

-- 4. JOIN: студенты с курсами
SELECT s.full_name, c.title, e.status, e.enrollment_date
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
ORDER BY s.full_name, c.title;

-- 5. Участники выбранного курса
SELECT s.full_name, s.group_name, e.status
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
WHERE c.title = 'Базы данных';

-- 6. Представление
CREATE VIEW student_courses AS
SELECT s.student_id,
       s.full_name,
       s.group_name,
       c.course_id,
       c.title AS course_title,
       e.enrollment_date,
       e.status
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id;

SELECT * FROM student_courses;

-- 7. Удаление одной записи из enrollments
DELETE FROM enrollments
WHERE student_id = 4 AND course_id = 1;

-- Проверка
SELECT s.full_name, c.title
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
ORDER BY s.full_name;

-- 8. Проверка ограничений
-- Повторная запись (должна упасть)
-- INSERT INTO enrollments (student_id, course_id) VALUES (1, 1);
-- Ошибка: duplicate key value violates unique constraint "uq_student_course"
-- Несуществующий студент (должна упасть)
-- INSERT INTO enrollments (student_id, course_id) VALUES (999, 1);
-- Ошибка: violates foreign key constraint
-- Несуществующий курс (должна упасть)
-- INSERT INTO enrollments (student_id, course_id) VALUES (1, 999);
-- Ошибка: violates foreign key constraint
-- Дополнительно: изменение статуса и отбор по статусу
UPDATE enrollments
SET status = 'completed'
WHERE student_id = 1 AND course_id = 1;

SELECT s.full_name, c.title, e.status
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
WHERE e.status = 'completed';


-- 4. Система проката велосипедов

-- 1. Сущности и связи:
--clients (клиенты) 1 ─── N  rentals
--bicycles (велосипеды) 1 ─── N  rentals
--rental_points (пункты проката) 1 ─── N  bicycles(где велосипед сейчас находится)
--rentals (аренды)  — связующая таблица многие-ко-многим
--между clients и bicycles + данные самой аренды

CREATE TABLE clients (
    client_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    phone       VARCHAR(20) UNIQUE,
    email       VARCHAR(100)
);

CREATE TABLE rental_points (
    point_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    address     VARCHAR(200) NOT NULL
);

CREATE TABLE bicycles (
    bicycle_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    model       VARCHAR(50) NOT NULL,
    brand       VARCHAR(50),
    status      VARCHAR(20) DEFAULT 'available'
                CHECK (status IN ('available', 'rented', 'maintenance')),
    point_id    INTEGER NOT NULL,
    CONSTRAINT fk_bicycles_point
        FOREIGN KEY (point_id) REFERENCES rental_points (point_id)
        ON DELETE RESTRICT
);

CREATE TABLE rentals (
    rental_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id       INTEGER NOT NULL,
    bicycle_id      INTEGER NOT NULL,
    start_time      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time        TIMESTAMP,                    -- NULL пока аренда активна
    cost            NUMERIC(10, 2),
    CONSTRAINT fk_rentals_client
        FOREIGN KEY (client_id) REFERENCES clients (client_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_rentals_bicycle
        FOREIGN KEY (bicycle_id) REFERENCES bicycles (bicycle_id)
        ON DELETE RESTRICT
);

-- 4. Тестовые данные
INSERT INTO clients (full_name, phone, email) VALUES
    ('Новиков Андрей', '+79001112233', 'novikov@mail.ru'),
    ('Морозова Екатерина', '+79004445566', 'morozova@mail.ru'),
    ('Фёдоров Павел', '+79007778899', 'fedorov@mail.ru');

INSERT INTO rental_points (name, address) VALUES
    ('Центральный', 'ул. Ленина, 10'),
    ('Парковый', 'ул. Парковая, 5'),
    ('Вокзальный', 'пл. Вокзальная, 1');

INSERT INTO bicycles (model, brand, status, point_id) VALUES
    ('City Cruiser', 'Trek', 'available', 1),
    ('Mountain Pro', 'Giant', 'available', 1),
    ('Urban 500', 'Specialized', 'available', 2),
    ('Folding X1', 'Brompton', 'available', 2),
    ('Road Race', 'Cannondale', 'available', 3);

INSERT INTO rentals (client_id, bicycle_id, start_time, end_time, cost) VALUES
    (1, 1, '2025-10-01 10:00:00', '2025-10-01 14:30:00', 450.00),
    (1, 3, '2025-10-05 09:15:00', '2025-10-05 12:00:00', 320.00),
    (2, 2, '2025-10-03 11:00:00', '2025-10-03 18:45:00', 780.00),
    (2, 4, '2025-10-08 08:30:00', NULL, NULL),                 -- активная аренда
    (3, 5, '2025-10-02 13:00:00', '2025-10-02 16:20:00', 410.00),
    (3, 1, '2025-10-10 15:00:00', '2025-10-10 19:00:00', 500.00);

-- 5. JOIN: список аренд с именами клиентов и моделями велосипедов
SELECT r.rental_id,
       c.full_name AS client_name,
       b.model AS bicycle_model,
       b.brand,
       r.start_time,
       r.end_time,
       r.cost
FROM rentals r
INNER JOIN clients c ON r.client_id = c.client_id
INNER JOIN bicycles b ON r.bicycle_id = b.bicycle_id
ORDER BY r.start_time;

-- 6. Аренды выбранного клиента
SELECT r.rental_id, b.model, r.start_time, r.end_time, r.cost
FROM rentals r
INNER JOIN clients c ON r.client_id = c.client_id
INNER JOIN bicycles b ON r.bicycle_id = b.bicycle_id
WHERE c.full_name = 'Новиков Андрей';

-- Аренды выбранного велосипеда
SELECT r.rental_id, c.full_name, r.start_time, r.end_time, r.cost
FROM rentals r
INNER JOIN clients c ON r.client_id = c.client_id
INNER JOIN bicycles b ON r.bicycle_id = b.bicycle_id
WHERE b.model = 'City Cruiser';

-- 7. Представление
CREATE VIEW rental_details AS
SELECT r.rental_id,
       c.client_id,
       c.full_name AS client_name,
       c.phone,
       b.bicycle_id,
       b.model AS bicycle_model,
       b.brand,
       r.start_time,
       r.end_time,
       r.cost,
       CASE WHEN r.end_time IS NULL THEN 'active' ELSE 'finished' END AS rental_status
FROM rentals r
INNER JOIN clients c ON r.client_id = c.client_id
INNER JOIN bicycles b ON r.bicycle_id = b.bicycle_id;

SELECT * FROM rental_details;

-- 8. Проверка ограничений
-- Аренда с несуществующим клиентом (должна упасть)
-- INSERT INTO rentals (client_id, bicycle_id) VALUES (999, 1);
-- Ошибка: violates foreign key constraint
-- Аренда с несуществующим велосипедом (должна упасть)
-- INSERT INTO rentals (client_id, bicycle_id) VALUES (1, 999);
-- Ошибка: violates foreign key constraint
-- Удаление клиента, на которого ссылаются аренды (должна упасть)
-- DELETE FROM clients WHERE full_name = 'Новиков Андрей';
-- Ошибка: update or delete on table "clients" violates foreign key constraint
-- Удаление велосипеда, на который ссылаются аренды (должна упасть)
-- DELETE FROM bicycles WHERE model = 'City Cruiser';
-- Ошибка: update or delete on table "bicycles" violates foreign key constraint
