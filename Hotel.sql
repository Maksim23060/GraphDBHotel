USE master;
GO
IF EXISTS(select 1 from sys.databases where name ='Hotel')
BEGIN
ALTER DATABASE Hotel SET single_user WITH ROLLBACK IMMEDIATE;
DROP DATABASE Hotel;
END;
GO

CREATE DATABASE Hotel;
GO

USE Hotel;
GO

-- ============================================================
-- 1. Создание таблиц узлов (NODE) 
-- ============================================================

-- Узел: Номер
CREATE TABLE Room 
(
    RoomId             INT IDENTITY(1,1) PRIMARY KEY,
    RoomNumber     NVARCHAR(10)  NOT NULL,
    RoomType       NVARCHAR(50)  NOT NULL,
    PricePerNight  DECIMAL(10,2) NOT NULL,
    Floor          INT           NOT NULL
) AS NODE;

-- Узел: Клиент
CREATE TABLE Customer 
(
    CustomerId               INT IDENTITY(1,1) PRIMARY KEY,
    FullName         NVARCHAR(100) NOT NULL,
    Phone            NVARCHAR(20)  NOT NULL,
    Email            NVARCHAR(100) NOT NULL,
    RegistrationDate DATE          NOT NULL DEFAULT GETDATE()
) AS NODE;

-- Узел: Услуга
CREATE TABLE Service 
(
    ServiceId           INT IDENTITY(1,1) PRIMARY KEY,
    ServiceName  NVARCHAR(100) NOT NULL,
    Description  NVARCHAR(200) NULL,
    BasePrice    DECIMAL(10,2) NOT NULL
) AS NODE;

-- ============================================================
-- 2. Создание таблиц рёбер (EDGE) с ограничениями соединений
-- ============================================================

-- Ребро: Бронирование (Клиент -> Номер)
CREATE TABLE Booking 
(
    BookingId    INT IDENTITY(1,1) PRIMARY KEY,
    CheckInDate  DATE           NOT NULL,
    CheckOutDate DATE           NOT NULL,
    Status       NVARCHAR(50)   NOT NULL,
    TotalCost    DECIMAL(10,2)  NOT NULL
) AS EDGE;
ALTER TABLE Booking ADD CONSTRAINT Booking_Customer_Room
    CONNECTION (Customer TO Room);

-- Ребро: Использование услуги (Клиент -> Сервис)
CREATE TABLE ServiceUsage
(
    UsageId        INT IDENTITY(1,1) PRIMARY KEY,
    UsageDate      DATE           NOT NULL,
    Quantity       INT            NOT NULL,
    TotalPrice     DECIMAL(10,2)  NOT NULL
) AS EDGE;
ALTER TABLE ServiceUsage ADD CONSTRAINT ServiceUsage_Customer_Service
    CONNECTION (Customer TO Service);

-- Ребро: Оснащение номера (Номер -> Сервис)
CREATE TABLE RoomService
(
    RoomServiceId  INT IDENTITY(1,1) PRIMARY KEY,
    AvailableSince DATE           NOT NULL,
    ExtraCharge    DECIMAL(10,2)  NULL
) AS EDGE;
ALTER TABLE RoomService ADD CONSTRAINT RoomService_Room_Service
    CONNECTION (Room TO Service);

-- ============================================================
-- 3. Заполнение таблиц узлов (Id автоматически)
-- ============================================================

-- Номера 
INSERT INTO Room (RoomNumber, RoomType, PricePerNight, Floor)
VALUES
    ('101', 'Стандарт',  2500.00, 1),
    ('102', 'Стандарт',  2500.00, 1),
    ('103', 'Стандарт+', 3200.00, 1),
    ('201', 'Полулюкс',  4500.00, 2),
    ('202', 'Полулюкс',  4500.00, 2),
    ('203', 'Люкс',      7000.00, 2),
    ('301', 'Стандарт',  2600.00, 3),
    ('302', 'Полулюкс',  4700.00, 3),
    ('303', 'Люкс',      7200.00, 3),
    ('401', 'Президентский люкс', 15000.00, 4);

-- Клиенты 
INSERT INTO Customer (FullName, Phone, Email, RegistrationDate)
VALUES
    ('Иванов Иван Иванович',    '+7 901 111-22-33', 'ivanov@mail.ru',      '2023-01-10'),
    ('Петрова Анна Сергеевна',  '+7 902 222-33-44', 'petrova@yandex.ru',   '2023-02-15'),
    ('Сидоров Павел Николаевич','+7 903 333-44-55', 'sidorov@gmail.com',   '2023-03-20'),
    ('Козлова Елена Викторовна','+7 904 444-55-66', 'kozlova@mail.ru',     '2023-04-25'),
    ('Морозов Дмитрий Алексеевич','+7 905 555-66-77','morozov@bk.ru',      '2023-05-30'),
    ('Волкова Ольга Петровна',  '+7 906 666-77-88', 'volkova@list.ru',     '2023-06-05'),
    ('Алексеев Андрей Владимирович','+7 907 777-88-99','alekseev@mail.ru', '2023-07-10'),
    ('Николаева Татьяна Игоревна','+7 908 888-99-00','nikolaeva@yandex.ru','2023-08-15'),
    ('Лебедев Сергей Михайлович','+7 909 999-00-11','lebedev@gmail.com',   '2023-09-20'),
    ('Соколова Ирина Дмитриевна','+7 910 000-11-22','sokolova@bk.ru',      '2023-10-25');

-- Услуги
INSERT INTO Service (ServiceName, Description, BasePrice)
VALUES
    ('Wi-Fi (безлимит)',     'Высокоскоростной интернет в номере',      0.00),
    ('Мини-бар',             'Напитки и закуски в номере',            500.00),
    ('Завтрак "шведский стол"','Буфет в ресторане отеля',            800.00),
    ('Фитнес-центр',         'Тренажёрный зал, 1 час',                600.00),
    ('Бассейн',              'Посещение крытого бассейна (2 часа)',   700.00),
    ('Спа-процедуры',        'Массаж, обёртывания (1 сеанс)',        2500.00),
    ('Трансфер от/до аэропорта','Комфортабельный автомобиль',       2000.00),
    ('Прачечная',            'Стирка и глажка (1 кг белья)',          400.00),
    ('Конференц-зал',        'Аренда зала на 2 часа',                3000.00),
    ('Экскурсионное обслуживание','Индивидуальный гид (3 часа)',    4500.00);

-- ============================================================
-- 4. Заполнение таблиц рёбер 
-- ============================================================

-- 4.1. Бронирования (Customer -> Room) 
INSERT INTO Booking ($from_id, $to_id, CheckInDate, CheckOutDate, Status, TotalCost)
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Иванов Иван Иванович'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '101'),
    '2025-06-01', '2025-06-05', 'Завершено', 2500.00 * 4
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Петрова Анна Сергеевна'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '202'),
    '2025-07-10', '2025-07-15', 'Завершено', 4500.00 * 5
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Сидоров Павел Николаевич'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '203'),
    '2025-08-20', '2025-08-25', 'Активно',   7000.00 * 5
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Козлова Елена Викторовна'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '401'),
    '2025-09-01', '2025-09-04', 'Активно',   15000.00 * 3
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Морозов Дмитрий Алексеевич'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '301'),
    '2025-09-12', '2025-09-14', 'Активно',   2600.00 * 2
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Волкова Ольга Петровна'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '102'),
    '2025-10-05', '2025-10-09', 'Активно',   2500.00 * 4
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Алексеев Андрей Владимирович'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '303'),
    '2025-10-20', '2025-10-24', 'Отменено',   7200.00 * 4
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Николаева Татьяна Игоревна'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '201'),
    '2025-11-01', '2025-11-06', 'Активно',   4500.00 * 5
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Лебедев Сергей Михайлович'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '103'),
    '2025-11-15', '2025-11-18', 'Активно',   3200.00 * 3
UNION ALL
SELECT
    (SELECT $node_id FROM Customer WHERE FullName = 'Соколова Ирина Дмитриевна'),
    (SELECT $node_id FROM Room WHERE RoomNumber = '302'),
    '2025-12-01', '2025-12-05', 'Активно',   4700.00 * 4;

-- 4.2. Использование услуг (Customer -> Service)
INSERT INTO ServiceUsage ($from_id, $to_id, UsageDate, Quantity, TotalPrice)
SELECT
    c.$node_id, s.$node_id, '2025-06-03', 1, s.BasePrice
FROM Customer c, Service s
WHERE c.FullName = 'Иванов Иван Иванович' AND s.ServiceName = 'Wi-Fi (безлимит)'
UNION ALL
SELECT
    c.$node_id, s.$node_id, '2025-06-04', 1, s.BasePrice
FROM Customer c, Service s
WHERE c.FullName = 'Иванов Иван Иванович' AND s.ServiceName = 'Завтрак "шведский стол"'
UNION ALL
SELECT
    c.$node_id, s.$node_id, '2025-07-11', 2, 600.00 * 2
FROM Customer c, Service s
WHERE c.FullName = 'Петрова Анна Сергеевна' AND s.ServiceName = 'Фитнес-центр'
UNION ALL
SELECT
    c.$node_id, s.$node_id, '2025-07-12', 1, s.BasePrice
FROM Customer c, Service s
WHERE c.FullName = 'Петрова Анна Сергеевна' AND s.ServiceName = 'Спа-процедуры'
UNION ALL
SELECT
    c.$node_id, s.$node_id, '2025-08-22', 1, s.BasePrice
FROM Customer c, Service s
WHERE c.FullName = 'Сидоров Павел Николаевич' AND s.ServiceName = 'Мини-бар'
UNION ALL
SELECT
    c.$node_id, s.$node_id, '2025-08-23', 1, 2000.00
FROM Customer c, Service s
WHERE c.FullName = 'Сидоров Павел Николаевич' AND s.ServiceName = 'Трансфер от/до аэропорта';

-- 4.3. Оснащение номеров (Room -> Service)
INSERT INTO RoomService ($from_id, $to_id, AvailableSince, ExtraCharge)
SELECT
    r.$node_id, s.$node_id, '2025-01-01', 0.00
FROM Room r, Service s
WHERE r.RoomNumber IN ('101','102','103','201','202','203','301','302','303','401')
  AND s.ServiceName = 'Wi-Fi (безлимит)'
UNION ALL
SELECT
    r.$node_id, s.$node_id, '2025-01-01', 500.00
FROM Room r, Service s
WHERE r.RoomNumber IN ('203','303','401') AND s.ServiceName = 'Мини-бар'
UNION ALL
SELECT
    r.$node_id, s.$node_id, '2025-01-01', 800.00
FROM Room r, Service s
WHERE r.RoomNumber IN ('201','202','203','302','303','401') AND s.ServiceName = 'Завтрак "шведский стол"'
UNION ALL
SELECT
    r.$node_id, s.$node_id, '2025-01-01', 0.00
FROM Room r, Service s
WHERE r.RoomNumber IN ('401') AND s.ServiceName = 'Конференц-зал';
GO

-- ============================================================
-- 5. Запросы с MATCH (с включением Id узлов)
-- ============================================================

-- Найти всех клиентов, которые бронировали номера, предоставляющие услугу 'Wi-Fi (безлимит)'
SELECT DISTINCT
    c.CustomerId AS CustomerId,
    c.FullName AS Клиент,
    r.RoomId AS RoomId,
    r.RoomNumber AS Номер,
    s.ServiceId AS ServiceId,
    s.ServiceName AS Услуга
FROM Customer c, Booking b, Room r, RoomService rs, Service s
WHERE MATCH( c-(b)->r-(rs)->s )
  AND s.ServiceName = 'Wi-Fi (безлимит)'
ORDER BY c.FullName;

-- Найти все услуги, доступные в номерах, которые бронировал клиент 'Сидоров Павел Николаевич'
SELECT DISTINCT
    s.ServiceId AS ServiceId,
    s.ServiceName AS Услуга,
    r.RoomId AS RoomId,
    r.RoomNumber AS Номер,
    b.CheckInDate AS Дата_заезда
FROM Customer c, Booking b, Room r, RoomService rs, Service s
WHERE MATCH( c-(b)->r-(rs)->s )
  AND c.FullName = 'Сидоров Павел Николаевич'
ORDER BY s.ServiceName;

-- Найти клиентов, которые использовали какую-либо услугу, и эта же услуга предоставлялась в номере, который они бронировали
SELECT 
    c.CustomerId AS CustomerId,
    c.FullName AS Клиент,
    s.ServiceId AS ServiceId,
    s.ServiceName AS Услуга,
    r.RoomId AS RoomId,
    r.RoomNumber AS Номер,
    su.UsageDate AS Дата_использования
FROM Customer c, ServiceUsage su, Service s, Booking b, Room r, RoomService rs
WHERE MATCH( c-(su)->s AND c-(b)->r-(rs)->s )
ORDER BY c.FullName, s.ServiceName;

-- Найти клиентов, которые бронировали номера на 2-м этаже и использовали услугу 'Спа-процедуры'
SELECT 
    c.CustomerId AS CustomerId,
    c.FullName AS Клиент,
    r.RoomId AS RoomId,
    r.RoomNumber AS Номер,
    r.Floor AS Этаж,
    su.UsageDate AS Дата_спа
FROM Customer c, Booking b, Room r, ServiceUsage su, Service s
WHERE MATCH( c-(b)->r AND c-(su)->s )
  AND r.Floor = 2
  AND s.ServiceName = 'Спа-процедуры'
ORDER BY c.FullName;

-- Для каждого клиента вывести общую стоимость бронирований и количество различных услуг, предоставленных в забронированных номерах
SELECT 
    c.CustomerId AS CustomerId,
    c.FullName AS Клиент,
    SUM(b.TotalCost) AS Итого_бронирований,
    COUNT(DISTINCT s.ServiceName) AS Различных_услуг_в_номерах
FROM Customer c, Booking b, Room r, RoomService rs, Service s
WHERE MATCH( c-(b)->r-(rs)->s )
GROUP BY c.CustomerId, c.FullName
ORDER BY Итого_бронирований DESC;

-- ============================================================
-- 6. Запросы с SHORTEST_PATH (включая Id узлов)
-- ============================================================

SELECT 
    Клиент,
    CustomerId,
    Путь_бронирований,
    Количество_номеров
FROM (
    SELECT
        c.FullName AS Клиент,
        c.CustomerId AS CustomerId,
        STRING_AGG(r.RoomNumber, ' -> ') WITHIN GROUP (GRAPH PATH) AS Путь_бронирований,
        COUNT(b.BookingId) WITHIN GROUP (GRAPH PATH) AS Количество_номеров 
    FROM
        Customer AS c,
        Booking FOR PATH AS b,
        Room FOR PATH AS r
    WHERE MATCH(SHORTEST_PATH(c(-(b)->r){1,3}))
      AND c.FullName = 'Иванов Иван Иванович'
) AS Q
WHERE Q.Количество_номеров = 1;

SELECT 
    Клиент,
    CustomerId,
    Номер,
    RoomId,
    Доступная_услуга,
    ServiceId,
    Длина_пути
FROM (
    SELECT
        c.FullName AS Клиент,
        c.CustomerId AS CustomerId,
        STRING_AGG(r.RoomNumber, ' -> ') WITHIN GROUP (GRAPH PATH) AS Номер,
        STRING_AGG(CAST(r.RoomId AS NVARCHAR(10)), ',') WITHIN GROUP (GRAPH PATH) AS RoomId,
        STRING_AGG(s.ServiceName, ' | ') WITHIN GROUP (GRAPH PATH) AS Доступная_услуга,
        STRING_AGG(CAST(s.ServiceId AS NVARCHAR(10)), ',') WITHIN GROUP (GRAPH PATH) AS ServiceId,
        COUNT(rs.RoomServiceId) WITHIN GROUP (GRAPH PATH) AS Длина_пути
    FROM
        Customer AS c,
        Booking FOR PATH AS b,
        Room FOR PATH AS r,
        RoomService FOR PATH AS rs,
        Service FOR PATH AS s
    WHERE MATCH(SHORTEST_PATH(c(-(b)->r-(rs)->s){1,3}))
      AND c.FullName = 'Сидоров Павел Николаевич'
) AS Q;
GO