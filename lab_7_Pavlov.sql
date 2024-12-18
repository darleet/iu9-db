USE master;
GO

IF DB_ID (N'lab7_db') IS NOT NULL
    DROP DATABASE lab7_db;
GO

-- Создание базы

CREATE DATABASE lab7_db
    ON (
    NAME = lab7_dat,
    FILENAME = N'/var/opt/mssql/data/lab7_dat.mdf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
    LOG ON (
    NAME = lab7_log,
    FILENAME = N'/var/opt/mssql/data/lab7_log.ldf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
GO

USE lab7_db;
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
    ('Nintendo', 'Japan', 'https://www.nintendo.com/', 'https://www.nintendo.com/'),
    ('Capcom', 'Japan', 'https://www.capcom.com/', 'https://www.capcom.com/'),
    ('Sega', 'Japan', 'https://www.sega.com/', 'https://www.sega.com/');
GO

CREATE TABLE Game (
    GameID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(511),
    Price DECIMAL(9, 2) NOT NULL,
    DeveloperID INT NOT NULL,
    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_Game_Price CHECK (Price >= 0),
    FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE CASCADE,
);
GO

INSERT INTO Game
    (GameName, ReleaseDate, Description, Price, DeveloperID)
VALUES
    ('The Legend of Zelda: Breath of the Wild', '2017-03-03', 'The Legend of Zelda: Breath of the Wild is an action-adventure game', 199.99, 1),
    ('Super Mario Odyssey', '2017-10-27', 'Super Mario Odyssey is an action-adventure game', 299.99, 1),
    ('Super Mario 64', '1996-09-21', 'Super Mario 64 is an action-adventure game', 59.99, 1),
    ('Super Smash Bros. Ultimate', '2018-10-26', 'Super Smash Bros. Ultimate is an action-adventure game', 59.99, 2),
    ('Super Mario 3D World', '2013-11-21', 'Super Mario 3D World is an action-adventure game', 59.99, 2);
GO

-- Для одной таблицы
CREATE VIEW GameView AS
    SELECT GameName, ReleaseDate, Description
    FROM Game;
GO

CREATE VIEW ExpensiveGameView AS
    SELECT GameName, ReleaseDate, Description, Price, DeveloperID
    FROM Game
    WHERE Price > 100
    WITH CHECK OPTION;
GO

INSERT INTO ExpensiveGameView
    (GameName, ReleaseDate, Description, Price, DeveloperID)
VALUES
    ('Mario Kart 8', '2014-11-18', 'Mario Kart 8 is an action-adventure game', 129.99, 1);
GO

-- нарушает CHECK OPTION
-- INSERT INTO ExpensiveGameView
--     (GameName, ReleaseDate, Description, Price, DeveloperID)
-- VALUES
--     ('Mario Kart 8', '2014-11-18', 'Mario Kart 8 is an action-adventure game', 59.99, 1);
-- GO

-- Для нескольких таблиц
CREATE VIEW DeveloperGameView AS
    SELECT D.DeveloperName, G.GameName
    FROM Developer AS D
    JOIN Game AS G ON D.DeveloperID = G.DeveloperID;
GO

CREATE INDEX IX_Game_Description
    ON Game (Description)
    INCLUDE (GameName, ReleaseDate);
GO

SELECT Description, GameName, ReleaseDate
    FROM Game
    WHERE Description LIKE 'Super Mario%';
GO

CREATE VIEW DeveloperGameIndexedView WITH SCHEMABINDING AS
    SELECT D.DeveloperName, G.GameName
    FROM dbo.Developer AS D
    JOIN dbo.Game AS G ON D.DeveloperID = G.DeveloperID;
GO
CREATE UNIQUE CLUSTERED INDEX IX_DeveloperGame ON DeveloperGameIndexedView (DeveloperName, GameName);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DeveloperGameName ON DeveloperGameIndexedView (GameName);
GO
