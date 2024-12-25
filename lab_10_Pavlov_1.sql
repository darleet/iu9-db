USE master;
GO

IF DB_ID (N'lab10_db') IS NOT NULL
    DROP DATABASE lab10_db;
GO

-- Создание базы

CREATE DATABASE lab10_db
    ON (
    NAME = lab10_dat,
    FILENAME = N'/var/opt/mssql/data/lab10_dat.mdf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
    LOG ON (
    NAME = lab10_log,
    FILENAME = N'/var/opt/mssql/data/lab10_log.ldf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
GO

USE lab10_db;
GO

CREATE TABLE Developer (
    DeveloperID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    DeveloperName NVARCHAR(63) NOT NULL,
    Location NVARCHAR(255),
    AvatarURL NVARCHAR(255),
    WebsiteURL NVARCHAR(255),
    CONSTRAINT AK_DeveloperName UNIQUE (DeveloperName)
);
GO

INSERT INTO Developer
(DeveloperName, Location, AvatarURL, WebsiteURL)
VALUES
    ('Nintendo', 'Japan', 'https://www.nintendo.com/', 'https://www.nintendo.com/'),
    ('Capcom', 'Japan', 'https://www.capcom.com/', 'https://www.capcom.com/'),
    ('Sega', 'Japan', 'https://www.sega.com/', 'https://www.sega.com/');
GO

---- READ UNCOMMITED
-- есть грязное чтение
-- есть невоспроизводимое
-- есть фантомное
PRINT 'READ UNCOMMITED';
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM Developer;
    WAITFOR DELAY '00:00:10';
    SELECT * FROM Developer;
COMMIT TRANSACTION;

---- READ COMMITED
-- нет грязного чтения
-- есть невоспроизводимое
-- есть фантомное
PRINT 'READ COMMITED';
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM Developer;
    WAITFOR DELAY '00:00:10';
    SELECT * FROM Developer;
    SELECT * FROM sys.dm_tran_locks;
COMMIT TRANSACTION;

---- REPEATABLE READ
-- нет грязного чтения
-- нет невоспроизводимого
-- есть фантомное
PRINT 'REPEATABLE READ';
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM Developer;
    WAITFOR DELAY '00:00:10';
    SELECT * FROM Developer;
    SELECT * FROM sys.dm_tran_locks;
COMMIT TRANSACTION;

-- Фантомное чтение, SERIALIZABLE
-- нет грязного чтения
-- нет невоспроизводимого
-- нет фантомного
PRINT 'SERIALIZABLE';
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT * FROM Developer;
    WAITFOR DELAY '00:00:10';
    SELECT * FROM Developer;
    SELECT * FROM sys.dm_tran_locks;
COMMIT TRANSACTION;
