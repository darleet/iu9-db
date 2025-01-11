USE master;
GO

IF DB_ID (N'lab13_1_db') IS NOT NULL
    DROP DATABASE lab13_1_db;
GO

IF DB_ID (N'lab13_2_db') IS NOT NULL
    DROP DATABASE lab13_2_db;
GO

-- Создание баз

CREATE DATABASE lab13_1_db
    ON (
    NAME = lab13_1_dat,
    FILENAME = N'/var/opt/mssql/data/lab13_1_dat.mdf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
    LOG ON (
    NAME = lab13_1_log,
    FILENAME = N'/var/opt/mssql/data/lab13_1_log.ldf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
GO

CREATE DATABASE lab13_2_db
    ON (
    NAME = lab13_2_dat,
    FILENAME = N'/var/opt/mssql/data/lab13_2_dat.mdf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
    LOG ON (
    NAME = lab13_2_log,
    FILENAME = N'/var/opt/mssql/data/lab13_2_log.ldf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
GO

USE lab13_1_db;
GO

CREATE TABLE Game (
    GameID INT PRIMARY KEY NOT NULL CHECK (GameID <= 100),
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) DEFAULT 0 NOT NULL,
    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_Game_Price CHECK (Price >= 0),
    INDEX IX_Game_GameName (GameName),
);
GO

USE lab13_2_db;
GO

CREATE TABLE Game (
    GameID INT PRIMARY KEY NOT NULL CHECK (GameID > 100),
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) DEFAULT 0 NOT NULL,
    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_Game_Price CHECK (Price >= 0),
    INDEX IX_Game_GameName (GameName),
);
GO

USE lab13_1_db;
GO

CREATE VIEW GameView
AS
    SELECT * FROM lab13_1_db.dbo.Game
    UNION ALL
    SELECT * FROM lab13_2_db.dbo.Game;
GO

-- INSERT

INSERT INTO GameView(GameID, GameName, ReleaseDate, Description, Price)
    VALUES
        (1, 'The Legend of Zelda: Breath of the Wild', '2017-03-03', 'The Legend of Zelda: Breath of the Wild is an action-adventure game', 199.99),
        (15, 'Super Mario Odyssey', '2017-10-27', 'Super Mario Odyssey is an action-adventure game', 299.99),
        (123, 'Super Mario 64', '1996-09-21', 'Super Mario 64 is an action-adventure game', 59.99),
        (244, 'Super Smash Bros. Ultimate', '2018-10-26', 'Super Smash Bros. Ultimate is an action-adventure game', 59.99),
        (501, 'Super Mario 3D World', '2013-11-21', NULL, 59.99);
GO

SELECT * FROM lab13_1_db.dbo.Game;
SELECT * FROM lab13_2_db.dbo.Game;
SELECT * FROM GameView;
GO

-- UPDATE

UPDATE GameView
    SET GameID = 13
    WHERE GameID = 123;
GO

SELECT * FROM lab13_1_db.dbo.Game;
SELECT * FROM lab13_2_db.dbo.Game;
SELECT * FROM GameView;
GO

-- DELETE

DELETE FROM GameView
    WHERE GameID BETWEEN 10 AND 200;
GO

SELECT * FROM lab13_1_db.dbo.Game;
SELECT * FROM lab13_2_db.dbo.Game;
SELECT * FROM GameView;
GO
