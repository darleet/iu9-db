USE master;
GO

IF DB_ID (N'lab6_db') IS NOT NULL
    DROP DATABASE lab6_db;
GO

-- Создание базы

CREATE DATABASE lab6_db
    ON (
    NAME = lab6_dat,
    FILENAME = N'/var/opt/mssql/data/lab6_dat.mdf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
    LOG ON (
    NAME = lab6_log,
    FILENAME = N'/var/opt/mssql/data/lab6_log.ldf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
GO

USE lab6_db;
GO

-- с автоинкрементным индикатором
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
    ('Nintendo', 'Japan', 'https://www.nintendo.com/', 'https://www.nintendo.com/');
GO

-- в текущем сеансе и в той же области видимости
SELECT SCOPE_IDENTITY() AS DeveloperIDFromScope;
GO

INSERT INTO Developer
    (DeveloperName, Location, AvatarURL, WebsiteURL)
VALUES
    ('Capcom', 'Japan', 'https://www.capcom.com/', 'https://www.capcom.com/');
GO

-- в текущем сеансе
SELECT @@IDENTITY AS DeveloperIDFromIdentity;
GO

INSERT INTO Developer
    (DeveloperName, Location, AvatarURL, WebsiteURL)
VALUES
    ('Sega', 'Japan', 'https://www.sega.com/', 'https://www.sega.com/');
GO

-- в любом сеансе для определенной таблицы
SELECT IDENT_CURRENT('Developer') AS DeveloperIDFromIdentCurrent;
GO

-- с уникальным глобальным идентификатором
CREATE TABLE Game (
    GameID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY NOT NULL,
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) NOT NULL,
    DeveloperID INT NOT NULL,

    -- добавлено для примера
    UpdatedAt DATETIME NOT NULL
        CONSTRAINT DF_Game_UpdatedAt DEFAULT GETDATE(),

    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_Game_Price CHECK (Price >= 0),

--     FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE SET NULL,
    FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE CASCADE,
--     FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE SET DEFAULT,
--     FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE NO ACTION,
);
GO

INSERT INTO Game
    (GameName, ReleaseDate, Description, Price, DeveloperID)
VALUES
    ('Super Smash Bros. Ultimate', '2018-10-26', 'The ultimate fighting game', 59.99, 1);
GO

DELETE Developer
WHERE DeveloperID = 1;
GO

-- incorrect values
-- INSERT INTO Game
-- (GameName, ReleaseDate, Description, Price, DeveloperID)
-- VALUES
--     ('Grand Theft Auto V', '2013-09-17', 'The ultimate driving game', -30.99, 1);
-- GO

CREATE SEQUENCE PlayerID
    START WITH 1
    INCREMENT BY 1;
GO

-- CREATE TABLE Player (
--     PlayerID INT DEFAULT NEXT VALUE FOR PlayerID PRIMARY KEY NOT NULL,
--     Email NVARCHAR(255) NOT NULL,
--     PublicName NVARCHAR(63) NOT NULL,
--     Description NVARCHAR(1023),
--     Country NVARCHAR(63),
--     City NVARCHAR(63),
--     AvatarURL NVARCHAR(255),
--     CONSTRAINT AK_PlayerEmail UNIQUE (Email),
-- );

-- можно без default, тогда нужно будет вручную присваивать следующее значение
CREATE TABLE Player (
    PlayerID INT PRIMARY KEY NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    PublicName NVARCHAR(63) NOT NULL,
    Description NVARCHAR(1023),
    Country NVARCHAR(63),
    City NVARCHAR(63),
    AvatarURL NVARCHAR(255),
    CONSTRAINT AK_PlayerEmail UNIQUE (Email),
);

INSERT INTO Player
    (PlayerID, Email, PublicName, Description, Country, City, AvatarURL)
VALUES
    (NEXT VALUE FOR PlayerID, '2h1iA@example.com', 'Ivan', 'The best player in the world', 'Russia', 'Moscow', 'https://www.nintendo.com/');
