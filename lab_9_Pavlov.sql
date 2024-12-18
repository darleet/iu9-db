USE master;
GO

IF DB_ID (N'lab9_db') IS NOT NULL
    DROP DATABASE lab9_db;
GO

-- Создание базы

CREATE DATABASE lab9_db
    ON (
    NAME = lab9_dat,
    FILENAME = N'/var/opt/mssql/data/lab9_dat.mdf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
    LOG ON (
    NAME = lab9_log,
    FILENAME = N'/var/opt/mssql/data/lab9_log.ldf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
GO

USE lab9_db;
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
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) NOT NULL,
    DeveloperID INT NOT NULL,
    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_Game_Price CHECK (Price >= 0),
    FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE CASCADE,
);
GO

-- INSERT
CREATE TRIGGER InsertGame
    ON Game
    FOR INSERT
AS
BEGIN
    PRINT 'Insert Trigger Called';
    SELECT * FROM inserted;
END;
GO

INSERT INTO Game
(GameName, ReleaseDate, Description, Price, DeveloperID)
VALUES
    ('The Legend of Zelda: Breath of the Wild', '2017-03-03', 'The Legend of Zelda: Breath of the Wild is an action-adventure game', 199.99, 1),
    ('Super Mario Odyssey', '2017-10-27', 'Super Mario Odyssey is an action-adventure game', 299.99, 1),
    ('Super Mario 64', '1996-09-21', 'Super Mario 64 is an action-adventure game', 59.99, 1),
    ('Super Smash Bros. Ultimate', '2018-10-26', 'Super Smash Bros. Ultimate is an action-adventure game', 59.99, 2),
    ('Super Mario 3D World', '2013-11-21', 'Super Mario 3D World is an action-adventure game', 159.99, 2);
GO

-- UPDATE
CREATE TRIGGER UpdateGame
    ON Game
    FOR UPDATE
AS
IF UPDATE(Price)
BEGIN
    PRINT 'Update Trigger Called';
    SELECT deleted.Price, inserted.Price FROM inserted
        JOIN deleted ON inserted.GameID = deleted.GameID;
END
GO

UPDATE Game
SET
    Price = 299.99
WHERE
    GameName = 'The Legend of Zelda: Breath of the Wild'
    AND ReleaseDate = '2017-03-03';
GO

-- DELETE
CREATE TRIGGER DeleteGame
    ON Developer
    FOR DELETE
AS
    IF 'Nintendo' IN (SELECT DeveloperName FROM deleted)
    BEGIN
        PRINT 'Delete Trigger Called';
        THROW 50000, 'Nintendo can not be deleted', 1;
    END;
GO

-- вызовет ошибку
-- DELETE FROM Developer
-- WHERE
--     DeveloperName = 'Nintendo';
-- GO

CREATE VIEW ExpensiveGameView AS
    SELECT G.GameName, G.ReleaseDate, G.Description, G.Price, D.DeveloperName
    FROM Game AS G
    JOIN Developer D on G.DeveloperID = D.DeveloperID
    WHERE Price > 100;
GO

-- INSERT
CREATE TRIGGER InsertExpensiveGame
    ON ExpensiveGameView
    INSTEAD OF INSERT
AS
    IF EXISTS(SELECT * FROM inserted WHERE Price < 100)
    BEGIN
        PRINT 'Insert Trigger Called';
        THROW 50000, 'Price must be gte than 100', 1;
    END;
    ELSE
    BEGIN
        INSERT INTO Game (GameName, ReleaseDate, Description, Price, DeveloperID)
            SELECT I.GameName, I.ReleaseDate, I.Description, I.Price, D.DeveloperID
            FROM inserted AS I
                JOIN Developer AS D
                    ON I.DeveloperName = D.DeveloperName
    END;
GO

INSERT INTO ExpensiveGameView
    (GameName, ReleaseDate, Description, Price, DeveloperName)
VALUES
    ('Mario Kart 8', '2014-11-18', 'Mario Kart 8 is an action-adventure game', 129.99, 'asldklasd'),
    ('Mario Kart 8', '2014-11-18', 'Mario Kart 8 is an action-adventure game', 129.99, 'Nintendo');
GO

-- вызовет ошибку
-- INSERT INTO ExpensiveGameView
--     (GameName, ReleaseDate, Description, Price, DeveloperID)
-- VALUES
--     ('Minesweeper', '2014-11-18', 'Minesweeper is an action-adventure game', 59.99, 1);
-- GO

-- DELETE
CREATE TRIGGER DeleteExpensiveGame
    ON ExpensiveGameView
    INSTEAD OF DELETE
AS
    IF 'Nintendo' IN (SELECT DeveloperName FROM deleted)
    BEGIN
        PRINT 'Delete Trigger Called';
        THROW 50000, 'Nintendo cannot be deleted!', 1;
    END;
    ELSE DELETE FROM Game WHERE GameName IN (SELECT GameName FROM deleted);
GO

DELETE FROM ExpensiveGameView
WHERE
    DeveloperName = 'Capcom';
GO

-- вызовет ошибку
-- DELETE FROM ExpensiveGameView
-- WHERE
--     DeveloperName = 'Nintendo';
-- GO

-- UPDATE
CREATE TRIGGER UpdateExpensiveGame
    ON ExpensiveGameView
    INSTEAD OF UPDATE
AS
    IF UPDATE(ReleaseDate)
    BEGIN
        PRINT 'Update Trigger Called';
        THROW 50000, 'Release date cannot be changed', 1;
    END;
    ELSE IF UPDATE(DeveloperName)
    BEGIN
        PRINT 'Update Trigger Called';
        THROW 50000, 'Developer Name cannot be changed', 2;
    END
GO

UPDATE ExpensiveGameView
SET
    GameName = 'Mario Expensive Edition'
WHERE
    GameName = 'Mario Kart 8';
GO

-- вызовет ошибку
-- UPDATE ExpensiveGameView
-- SET
--     ReleaseDate = '2014-11-18'
-- WHERE
--     GameName = 'Mario Kart 8';
-- GO

-- MERGE

DROP TRIGGER InsertGame;
DROP TRIGGER UpdateGame;
DROP TRIGGER DeleteGame;

CREATE TABLE NewGame (
    GameID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) NOT NULL,
    DeveloperID INT NOT NULL,
    CONSTRAINT AK_NewGameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_NewGame_Price CHECK (Price >= 0),
    FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE CASCADE,
)
GO

INSERT INTO NewGame
    (GameName, ReleaseDate, Description, Price, DeveloperID)
VALUES
    ('Minesweeper', '2014-11-18', 'Minesweeper is an action-adventure game', 59.99, 1),
    ('Super Smash Bros. Ultimate', '2013-11-21', 'Super Mario 3D was remade!', 129.99, 2);
GO

CREATE TRIGGER InsertGame
    ON Game
    FOR INSERT
AS
    BEGIN
        PRINT 'Merge Game Insert';
        SELECT * FROM inserted;
    END;
GO

CREATE TRIGGER UpdateGame
    ON Game
    FOR UPDATE
AS
    BEGIN
        PRINT 'Merge Game Update';
        SELECT * FROM inserted;
        SELECT * FROM deleted;
    END;
GO

CREATE TRIGGER DeleteGame
    ON Game
    FOR DELETE
AS
    BEGIN
        PRINT 'Merge Game Delete';
        SELECT * FROM deleted;
    END;
GO

CREATE TRIGGER InsertNewGame
    ON NewGame
    FOR INSERT
AS
    BEGIN
        PRINT 'Merge New Game Insert';
        SELECT * FROM inserted;
    END;
GO

CREATE TRIGGER UpdateNewGame
    ON NewGame
    FOR UPDATE
AS
    BEGIN
        PRINT 'Merge New Game Update';
        SELECT * FROM inserted;
        SELECT * FROM deleted;
    END;
GO

CREATE TRIGGER DeleteNewGame
    ON NewGame
    FOR DELETE
AS
    BEGIN
        PRINT 'Merge New Game Delete';
        SELECT * FROM deleted;
    END;
GO

MERGE INTO Game AS G
    USING NewGame AS N
    ON G.GameName = N.GameName
WHEN MATCHED THEN
    UPDATE SET
        G.Description = N.Description,
        G.Price = N.Price
WHEN NOT MATCHED THEN
    INSERT
        (GameName, ReleaseDate, Description, Price, DeveloperID)
    VALUES
        (N.GameName, N.ReleaseDate, N.Description, N.Price, N.DeveloperID);
GO
