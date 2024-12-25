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

CREATE TABLE App (
    AppID UNIQUEIDENTIFIER PRIMARY KEY NOT NULL,
    DownloadURL NVARCHAR(255) NOT NULL,
    SizeInBytes BIGINT NOT NULL,
    GameID UNIQUEIDENTIFIER,
)

CREATE TABLE Game (
    GameID UNIQUEIDENTIFIER PRIMARY KEY NOT NULL,
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) NOT NULL,
    AppID UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_Game_Price CHECK (Price >= 0),
    FOREIGN KEY (AppID) REFERENCES App(AppID) ON DELETE NO ACTION,
);
GO

ALTER TABLE App
    ADD FOREIGN KEY (GameID) REFERENCES Game(GameID) ON DELETE SET NULL;
GO

INSERT INTO App
    (AppID, DownloadURL, SizeInBytes)
VALUES
    ('ce2047a1-9f05-4b20-a047-a19f05cb20ae', 'https://www.example.com/legend-of-zelda.apk', 12345678),
    ('5cd689fc-55b1-42f5-9689-fc55b1c2f541', 'https://www.example.com/super-mario-odyssey.apk', 23456789),
    ('2a7fb09d-16e5-47e5-bfb0-9d16e567e5f6', 'https://www.example.com/super-mario-64.apk', 34567890),
    ('4e6dc99f-3369-48d2-adc9-9f3369c8d201', 'https://www.example.com/super-smash-bros-ultimate.apk', 45678901),
    ('eba9f275-f774-429e-a9f2-75f774b29e46', 'https://www.example.com/super-mario-3d-world.apk', 56789012),
    ('0f9670a5-5d65-4cfa-9670-a55d650cfa99', 'https://www.example.com/steam.apk', 67890123),
    ('5bfbee35-796e-4694-bbee-35796ee69408', 'https://www.example.com/epic-games.apk', 78901234),
    ('9b8fdd90-ab6f-494e-8fdd-90ab6fb94eea', 'https://www.example.com/game-1.apk', 2893194),
    ('a51ed946-d8a5-4afd-9ed9-46d8a52afd77', 'https://www.example.com/game-2.apk', 21998312);
GO

-- INSERT
CREATE TRIGGER InsertGame
    ON Game
    FOR INSERT
AS
BEGIN
    PRINT 'Insert Trigger Called';
    SELECT * FROM inserted;
    UPDATE App
        SET GameID = i.GameID
        FROM inserted AS i
        WHERE App.AppID = i.AppID;
END;
GO

INSERT INTO Game
    (GameID, GameName, ReleaseDate, Description, Price, AppID)
VALUES
    ('e4ce4c8e-b7dc-4c5e-8e4c-8eb7dcac5e43', 'The Legend of Zelda: Breath of the Wild', '2017-03-03', 'The Legend of Zelda: Breath of the Wild is an action-adventure game', 199.99, 'ce2047a1-9f05-4b20-a047-a19f05cb20ae'),
    ('16813450-7322-4983-8134-507322298374', 'Super Mario Odyssey', '2017-10-27', 'Super Mario Odyssey is an action-adventure game', 299.99, '5cd689fc-55b1-42f5-9689-fc55b1c2f541'),
    ('9aaeda5e-7f08-49d5-aeda-5e7f0849d576', 'Super Mario 64', '1996-09-21', 'Super Mario 64 is an action-adventure game', 59.99, '2a7fb09d-16e5-47e5-bfb0-9d16e567e5f6'),
    ('637fbc25-26c3-4117-bfbc-2526c3c117fa', 'Super Smash Bros. Ultimate', '2018-10-26', 'Super Smash Bros. Ultimate is an action-adventure game', 59.99, '4e6dc99f-3369-48d2-adc9-9f3369c8d201'),
    ('915305f3-fa56-4700-9305-f3fa562700b7', 'Super Mario 3D World', '2013-11-21', 'Super Mario 3D World is an action-adventure game', 159.99, 'eba9f275-f774-429e-a9f2-75f774b29e46');
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
    ON Game
    FOR DELETE
AS
    DELETE FROM App WHERE AppID IN (SELECT AppID FROM deleted);
GO

-- View

CREATE VIEW GameAppView AS
    SELECT G.GameID, G.GameName, G.ReleaseDate, G.Description, G.Price,
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
            (GameID, GameName, ReleaseDate, Description, Price, AppID)
        SELECT GameID, GameName, ReleaseDate, Description, Price, AppID FROM inserted;
    END;
GO

INSERT INTO GameAppView
    (GameID, GameName, ReleaseDate, Description, Price, AppID, DownloadURL, SizeInBytes)
VALUES
    (NEWID(), 'Minecraft', '2011-11-18', 'Minecraft is an action-adventure game', 59.99, '94d3b090-7574-4f65-93b0-907574ef65f8', 'https://www.example.com/mine.apk', 123456789),
    (NEWID(), 'Mortal Kombat', '2013-11-21', 'Mortal Kombat is an action-adventure game', 129.99, 'a80b4496-ddd8-4528-8b44-96ddd855284a', 'https://www.example.com/mortal-kombat.apk', 234567890);
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

-- MERGE

DROP TRIGGER InsertGame;
DROP TRIGGER UpdateGame;
DROP TRIGGER DeleteGame;

CREATE TABLE NewGame (
    GameID UNIQUEIDENTIFIER PRIMARY KEY NOT NULL,
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) NOT NULL,
    AppID UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT AK_NewGameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_NewGame_Price CHECK (Price >= 0),
    FOREIGN KEY (AppID) REFERENCES App(AppID) ON DELETE NO ACTION,
)
GO

INSERT INTO NewGame
    (GameID, GameName, ReleaseDate, Description, Price, AppID)
VALUES
    (NEWID(), 'Minesweeper', '2014-11-18', 'Minesweeper is an action-adventure game', 59.99, '9b8fdd90-ab6f-494e-8fdd-90ab6fb94eea'),
    (NEWID(), 'Super Mario 3D World', '2013-11-21', 'Super Mario 3D was remade!', 129.99, 'a51ed946-d8a5-4afd-9ed9-46d8a52afd77');
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
        (GameID, GameName, ReleaseDate, Description, Price, AppID)
    VALUES
        (N.GameID, N.GameName, N.ReleaseDate, N.Description, N.Price, N.AppID);
GO
