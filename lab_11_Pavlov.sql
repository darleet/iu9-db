USE master;
GO

IF DB_ID (N'lab11_db') IS NOT NULL
    DROP DATABASE lab11_db;
GO

-- Создание базы

CREATE DATABASE lab11_db
    ON (
        NAME = lab11_dat,
        FILENAME = N'/var/opt/mssql/data/lab11_dat.mdf',
        SIZE = 5MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 5MB
    )
    LOG ON (
        NAME = lab11_log,
        FILENAME = N'/var/opt/mssql/data/lab11_log.ldf',
        SIZE = 5MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 5MB
    )
GO

USE lab11_db;
GO

CREATE TABLE Developer (
    DeveloperID INT PRIMARY KEY NOT NULL,
    DeveloperName NVARCHAR(63) NOT NULL,
    Location NVARCHAR(255),
    AvatarURL NVARCHAR(255),
    WebsiteURL NVARCHAR(255),
    CONSTRAINT AK_DeveloperName UNIQUE (DeveloperName)
);
GO

INSERT INTO Developer
    (DeveloperID, DeveloperName, Location, AvatarURL, WebsiteURL)
VALUES
    (1, 'Nintendo', 'Japan', 'https://www.gravatar.com/avatar/1', 'https://www.nintendo.com/'),
    (2, 'Capcom', 'Japan', 'https://www.gravatar.com/avatar/4', 'https://www.capcom.com/'),
    (3, 'Sega', 'Japan', 'https://www.gravatar.com/avatar/5', 'https://www.sega.com/');
GO

CREATE TABLE App (
    AppID INT PRIMARY KEY NOT NULL,
    DownloadURL NVARCHAR(255) NOT NULL,
    SizeInBytes BIGINT NOT NULL,
    GameID INT,
)

CREATE UNIQUE NONCLUSTERED INDEX UQ_App_GameID_NotNull
    ON App(GameID) WHERE GameID IS NOT NULL;

INSERT INTO App
    (AppID, DownloadURL, SizeInBytes)
VALUES
    (1, 'https://www.example.com/legend-of-zelda.apk', 12345678),
    (2, 'https://www.example.com/super-mario-odyssey.apk', 23456789),
    (3, 'https://www.example.com/super-mario-64.apk', 34567890),
    (4, 'https://www.example.com/super-smash-bros-ultimate.apk', 45678901),
    (5, 'https://www.example.com/super-mario-3d-world.apk', 56789012),
    (6, 'https://www.example.com/steam.apk', 67890123),
    (7, 'https://www.example.com/epic-games.apk', 78901234),
    (8, 'https://www.example.com/game-1.apk', 2893194),
    (9, 'https://www.example.com/game-2.apk', 21998312);
GO

CREATE TABLE Game (
    GameID INT PRIMARY KEY NOT NULL,
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) DEFAULT 0 NOT NULL,
    DeveloperID INT NOT NULL,
    AppID INT UNIQUE NOT NULL,
    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_Game_Price CHECK (Price >= 0),
    FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE CASCADE,
    FOREIGN KEY (AppID) REFERENCES App(AppID) ON DELETE NO ACTION,
    INDEX IX_Game_GameName (GameName),
);
GO

ALTER TABLE App
    ADD FOREIGN KEY (GameID) REFERENCES Game(GameID) ON DELETE SET NULL;
GO

INSERT INTO Game
    (GameID, GameName, ReleaseDate, Description, Price, DeveloperID, AppID)
VALUES
    (1, 'The Legend of Zelda: Breath of the Wild', '2017-03-03', 'The Legend of Zelda: Breath of the Wild is an action-adventure game', 199.99, 1, 1),
    (2, 'Super Mario Odyssey', '2017-10-27', 'Super Mario Odyssey is an action-adventure game', 299.99, 1, 2),
    (3, 'Super Mario 64', '1996-09-21', 'Super Mario 64 is an action-adventure game', 59.99, 1, 3),
    (4, 'Super Smash Bros. Ultimate', '2018-10-26', 'Super Smash Bros. Ultimate is an action-adventure game', 59.99, 2, 4),
    (5, 'Super Mario 3D World', '2013-11-21', NULL, 59.99, 2, 5);
GO

-- with default
INSERT INTO Game
    (GameID, GameName, ReleaseDate, Description, DeveloperID, AppID)
VALUES
    (6, 'Street Fighter V', '2016-12-08', 'Street Fighter V is an action-adventure game', 3, 8);
GO

DELETE FROM Game
    WHERE GameName = 'Super Mario Odyssey' OR Description IS NULL;
GO

CREATE TABLE AdditionalAgreement (
    AdditionalAgreementID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    AdditionalAgreementName NVARCHAR(255) UNIQUE NOT NULL,
    DocumentURL NVARCHAR(255) NOT NULL,
    DeveloperID INT NOT NULL,
    FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID) ON DELETE CASCADE,
);
GO

INSERT INTO AdditionalAgreement
    (AdditionalAgreementName, DocumentURL, DeveloperID)
VALUES
    ('EULA', 'https://www.nintendo.com/eula/', (SELECT DeveloperID FROM Developer WHERE DeveloperName = 'Nintendo'));
GO

CREATE TABLE Player (
    PlayerID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    Email NVARCHAR(255) UNIQUE NOT NULL,
    PublicName NVARCHAR(63) NOT NULL,
    Description NVARCHAR(255),
    Country NVARCHAR(63),
    City NVARCHAR(63),
    AvatarURL NVARCHAR(255),
    INDEX IX_Player_PublicName (PublicName),
);
GO

INSERT INTO Player
(Email, PublicName, Description, Country, City, AvatarURL)
VALUES
    ('Q4YqS@example.com', 'Player 1', 'Player 1 description', 'Russia', 'Moscow', 'https://www.gravatar.com/avatar/1'),
    ('4M7lP@example.com', 'Player 2', 'Player 2 description', 'USA', 'New York', 'https://www.gravatar.com/avatar/2'),
    ('o210aS@example.com', 'Player 3', 'Player 3 description', 'USA', 'Washington, D.C.', 'https://www.gravatar.com/avatar/3');
GO

-- View

CREATE VIEW GameAppView AS
SELECT G.GameID, G.GameName, G.ReleaseDate, G.Description, G.Price, G.DeveloperID,
       A.AppID, A.DownloadURL, A.SizeInBytes
FROM Game AS G
         JOIN App AS A ON G.GameID = A.GameID
GO

-- INSERT
CREATE TRIGGER InsertGameApp
    ON GameAppView
    INSTEAD OF INSERT
    AS
BEGIN
    INSERT INTO App
    (AppID, DownloadURL, SizeInBytes)
    SELECT AppID, DownloadURL, SizeInBytes FROM inserted;

    INSERT INTO Game
    (GameID, GameName, ReleaseDate, Description, Price, DeveloperID, AppID)
    SELECT GameID, GameName, ReleaseDate, Description, Price, DeveloperID, AppID FROM inserted;
END;
GO

INSERT INTO GameAppView
    (GameID, GameName, ReleaseDate, Description, Price, DeveloperID, AppID, DownloadURL, SizeInBytes)
VALUES
    (7, 'Minecraft', '2011-11-18', 'Minecraft is an action-adventure game', 59.99, 3, 10, 'https://www.example.com/mine.apk', 123456789),
    (8, 'Mortal Kombat', '2013-11-21', 'Mortal Kombat is an action-adventure game', 129.99, 3, 11, 'https://www.example.com/mortal-kombat.apk', 234567890);
GO

-- DELETE
CREATE TRIGGER DeleteGameApp
    ON GameAppView
    INSTEAD OF DELETE
    AS
BEGIN
    DELETE FROM Game
    WHERE
        GameID IN (SELECT GameID FROM deleted);

    DELETE FROM App
    WHERE
        AppID IN (SELECT AppID FROM deleted);
END;
GO

DELETE FROM GameAppView
WHERE
    GameName = 'Super Smash Bros. Ultimate';
GO

-- UPDATE
CREATE TRIGGER UpdateGameApp
    ON GameAppView
    INSTEAD OF UPDATE
    AS
BEGIN
    IF UPDATE(GameID) OR UPDATE(AppID)
        THROW 50001, 'GameID or AppID should not be changed', 1

    UPDATE App
    SET
        DownloadURL = i.DownloadURL,
        SizeInBytes = i.SizeInBytes
    FROM inserted AS i
    WHERE
        App.AppID = i.AppID;

    UPDATE Game
    SET
        GameName = i.GameName,
        ReleaseDate = i.ReleaseDate,
        Description = i.Description,
        Price = i.Price
    FROM inserted AS i
    WHERE
        Game.GameID = i.GameID;
END;
GO

UPDATE GameAppView
SET
    GameName = 'The UPDATED Legend of Zelda',
    Description = 'HUGE UPDATE!!',
    DownloadURL = 'https://www.example.com/updated.apk'
WHERE
    GameName = 'The Legend of Zelda: Breath of the Wild';
GO

CREATE TABLE GamePlayerInt (
    GameID INT NOT NULL,
    PlayerID INT NOT NULL,
    CONSTRAINT PK_GameID_PlayerID PRIMARY KEY (GameID, PlayerID),
    FOREIGN KEY (GameID) REFERENCES Game(GameID) ON DELETE CASCADE,
    FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID) ON DELETE CASCADE,
);
GO

INSERT INTO GamePlayerInt
    (GameID, PlayerID)
VALUES
    ((SELECT GameID FROM Game WHERE GameName = 'Street Fighter V'), (SELECT PlayerID FROM Player WHERE PublicName = 'Player 1')),
    ((SELECT GameID FROM Game WHERE GameName = 'The Legend of Zelda: Breath of the Wild'), (SELECT PlayerID FROM Player WHERE PublicName = 'Player 1')),
    ((SELECT GameID FROM Game WHERE GameName = 'The Legend of Zelda: Breath of the Wild'), (SELECT PlayerID FROM Player WHERE PublicName = 'Player 3'));
GO

SELECT P.PublicName, COUNT(*) AS GameCount FROM Player AS P
    INNER JOIN GamePlayerInt ON P.PlayerID = GamePlayerInt.PlayerID
    INNER JOIN Game AS G ON G.GameID = GamePlayerInt.GameID
    GROUP BY PublicName
    ORDER BY PublicName;
GO

SELECT DISTINCT Country FROM Player;
GO

UPDATE Game
    SET Description = 'MARIO IS SUPER GOOD!'
    WHERE GameName LIKE 'Super%';
GO

SELECT * FROM Game
    WHERE Price BETWEEN 100 AND 200;
GO

SELECT P.PublicName AS PlayerName, G.GameName FROM Player AS P
    LEFT JOIN GamePlayerInt ON P.PlayerID = GamePlayerInt.PlayerID
    LEFT JOIN Game AS G ON G.GameID = GamePlayerInt.GameID;
GO

SELECT P.PublicName AS PlayerName, G.GameName FROM Player AS P
    RIGHT JOIN GamePlayerInt ON P.PlayerID = GamePlayerInt.PlayerID
    LEFT JOIN Game AS G ON G.GameID = GamePlayerInt.GameID;
GO

SELECT P.PublicName AS PlayerName, G.GameName FROM Player AS P
    RIGHT JOIN GamePlayerInt ON P.PlayerID = GamePlayerInt.PlayerID
    RIGHT JOIN Game AS G ON G.GameID = GamePlayerInt.GameID;
GO

SELECT P.PublicName AS PlayerName, G.GameName FROM Player AS P
    FULL OUTER JOIN GamePlayerInt ON P.PlayerID = GamePlayerInt.PlayerID
    FULL OUTER JOIN Game AS G ON G.GameID = GamePlayerInt.GameID;
GO

-- Aggregation

SELECT D.DeveloperName, SUM(G.Price) FROM Game AS G
    INNER JOIN Developer AS D ON G.DeveloperID = D.DeveloperID
    GROUP BY D.DeveloperName;
GO

SELECT D.DeveloperName, AVG(G.Price) FROM Game AS G
    INNER JOIN Developer D on G.DeveloperID = D.DeveloperID
    GROUP BY D.DeveloperName;
GO

SELECT D.DeveloperName, MIN(G.Price) FROM Game AS G
    INNER JOIN Developer D on G.DeveloperID = D.DeveloperID
    GROUP BY D.DeveloperName;
GO

SELECT D.DeveloperName, MAX(G.Price) FROM Game AS G
    INNER JOIN Developer D on G.DeveloperID = D.DeveloperID
    GROUP BY D.DeveloperName;
GO

SELECT D.DeveloperName, COUNT(*) FROM Game AS G
    INNER JOIN Developer D on G.DeveloperID = D.DeveloperID
    GROUP BY D.DeveloperName;
GO

SELECT AvatarURL FROM Player
UNION
SELECT AvatarURL FROM Developer;
GO

SELECT AvatarURL FROM Player
UNION ALL
SELECT AvatarURL FROM Developer;
GO

SELECT AvatarURL FROM Player
INTERSECT
SELECT AvatarURL FROM Developer;
GO

SELECT AvatarURL FROM Player
EXCEPT
SELECT AvatarURL FROM Developer;
GO

-- Вложенный запрос
SELECT * FROM Game
    WHERE Price < (SELECT AVG(Price) FROM Game);
GO
