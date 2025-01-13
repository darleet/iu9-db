USE lab13_1_db;
GO

DROP TABLE IF EXISTS Developer;
GO
DROP TABLE IF EXISTS Game;
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

USE lab13_2_db;
GO

DROP TABLE IF EXISTS Developer;
GO
DROP TABLE IF EXISTS Game;
GO

CREATE TABLE Game (
    GameID INT PRIMARY KEY NOT NULL,
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) DEFAULT 0 NOT NULL,
    DeveloperID INT NOT NULL,
    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT CHK_Game_Price CHECK (Price >= 0),
    INDEX IX_Game_GameName (GameName),
);
GO

-- View

DROP VIEW IF EXISTS GameDeveloperView;
GO

CREATE VIEW GameDeveloperView
AS
    SELECT G.GameID, G.GameName, G.ReleaseDate, G.Description, G.Price,
           D.DeveloperID, D.DeveloperName, D.Location, D.AvatarURL, D.WebsiteURL
    FROM lab13_2_db.dbo.Game AS G
        INNER JOIN lab13_1_db.dbo.Developer D on G.DeveloperID = D.DeveloperID
GO

SELECT * FROM GameDeveloperView;
GO

-- INSERT

DROP TRIGGER IF EXISTS GameInsertUpdateTrigger;
GO

CREATE TRIGGER GameInsertUpdateTrigger ON lab13_2_db.dbo.Game
    FOR INSERT, UPDATE
    AS
        BEGIN
            IF EXISTS(SELECT DeveloperID FROM inserted AS i
                      WHERE i.DeveloperID NOT IN
                            (SELECT DeveloperID FROM lab13_1_db.dbo.Developer))
                THROW 50001, 'DeveloperID does not exist in lab13_1_db.dbo.Developer', 1;
        END;
GO

INSERT INTO lab13_1_db.dbo.Developer
    (DeveloperID, DeveloperName, Location, AvatarURL, WebsiteURL)
VALUES
    (1, 'Nintendo', 'Japan', 'https://www.gravatar.com/avatar/1', 'https://www.nintendo.com/'),
    (2, 'Capcom', 'Japan', 'https://www.gravatar.com/avatar/4', 'https://www.capcom.com/'),
    (3, 'Sega', 'Japan', 'https://www.gravatar.com/avatar/5', 'https://www.sega.com/');
GO

INSERT INTO lab13_2_db.dbo.Game
    (GameID, GameName, ReleaseDate, Description, Price, DeveloperID)
VALUES
    (1, 'The Legend of Zelda: Breath of the Wild', '2017-03-03', 'The Legend of Zelda: Breath of the Wild is an action-adventure game', 199.99, 1),
    (2, 'Super Mario Odyssey', '2017-10-27', 'Super Mario Odyssey is an action-adventure game', 299.99, 1),
    (3, 'Super Mario 64', '1996-09-21', 'Super Mario 64 is an action-adventure game', 59.99, 1),
    (4, 'Super Smash Bros. Ultimate', '2018-10-26', 'Super Smash Bros. Ultimate is an action-adventure game', 59.99, 2),
    (5, 'Super Mario 3D World', '2013-11-21', NULL, 59.99, 3);
GO

SELECT * FROM GameDeveloperView;
SELECT * FROM lab13_1_db.dbo.Developer;
SELECT * FROM lab13_2_db.dbo.Game;

-- UPDATE

DROP TRIGGER IF EXISTS GameUpdateTrigger;
GO

UPDATE lab13_2_db.dbo.Game
SET GameName = 'UPDATED Legend of Zelda', Description = 'THE GAME HAS BEEN UPDATED!!!'
WHERE GameName = 'The Legend of Zelda: Breath of the Wild'
GO

SELECT * FROM GameDeveloperView;
SELECT * FROM lab13_1_db.dbo.Developer;
SELECT * FROM lab13_2_db.dbo.Game;

-- DELETE

DROP TRIGGER IF EXISTS GameDeleteTrigger;
GO

CREATE TRIGGER GameDeleteTrigger ON lab13_2_db.dbo.Game
    FOR DELETE
    AS
        -- Delete developers without games
        DELETE FROM lab13_1_db.dbo.Developer
        WHERE DeveloperID IN (
            SELECT D.DeveloperID FROM lab13_1_db.dbo.Developer AS D
                LEFT JOIN dbo.Game G ON D.DeveloperID = G.DeveloperID
                WHERE G.GameID IS NULL
        );
GO

DELETE FROM lab13_2_db.dbo.Game
WHERE GameID = 5;
GO

SELECT * FROM GameDeveloperView;
SELECT * FROM lab13_1_db.dbo.Developer;
SELECT * FROM lab13_2_db.dbo.Game;
GO

-- Developer
-- DELETE

USE lab13_1_db;
GO

DROP TRIGGER IF EXISTS DeveloperDeleteUpdateTrigger;
GO

CREATE TRIGGER DeveloperDeleteUpdateTrigger ON lab13_1_db.dbo.Developer
    FOR DELETE, UPDATE
    AS
        IF EXISTS(SELECT 1 FROM lab13_2_db.dbo.Game
                           WHERE DeveloperID IN (SELECT DeveloperID FROM deleted))
            THROW 50001, 'Cannot delete Developer with Games', 1;
GO


-- DELETE FROM lab13_1_db.dbo.Developer
-- WHERE DeveloperID = 1;

-- UPDATE lab13_1_db.dbo.Developer
-- SET DeveloperID = 4
-- WHERE DeveloperID = 1;

