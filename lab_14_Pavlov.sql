USE lab13_1_db;
GO

DROP TABLE IF EXISTS Player;
GO

-- Public data
CREATE TABLE Player (
    PlayerID INT PRIMARY KEY NOT NULL,
    PublicName NVARCHAR(63) NOT NULL,
    Description NVARCHAR(255),
    AvatarURL NVARCHAR(255),
    INDEX IX_Player_PublicName (PublicName),
);
GO

USE lab13_2_db;
GO

DROP TABLE IF EXISTS Player;
GO

-- Private data
CREATE TABLE Player (
    PlayerID INT PRIMARY KEY NOT NULL,
    Email NVARCHAR(255) UNIQUE NOT NULL,
    Country NVARCHAR(63),
    City NVARCHAR(63),
);
GO

USE lab13_1_db;
GO

-- View

DROP VIEW IF EXISTS PlayerView;
GO

CREATE VIEW PlayerView
AS
    SELECT P1.PlayerID, P1.PublicName, P1.Description, P1.AvatarURL,
           P2.Email, P2.Country, P2.City
        FROM lab13_1_db.dbo.Player AS P1, lab13_2_db.dbo.Player AS P2
        WHERE P1.PlayerID = P2.PlayerID;
GO

-- INSERT

DROP TRIGGER IF EXISTS PlayerViewInsertTrigger;
GO

CREATE TRIGGER PlayerViewInsertTrigger ON PlayerView
    INSTEAD OF INSERT
    AS
        BEGIN
            INSERT INTO lab13_1_db.dbo.Player(PlayerID, PublicName, Description, AvatarURL)
                SELECT i.PlayerID, i.PublicName, i.Description, i.AvatarURL FROM inserted AS i;

            INSERT INTO lab13_2_db.dbo.Player(PlayerID, Email, Country, City)
                SELECT i.PlayerID, i.Email, i.Country, i.City FROM inserted AS i;
        END;
GO

INSERT INTO PlayerView(PlayerID, PublicName, Description, AvatarURL, Email, Country, City)
    VALUES
        (1, 'Player 1', 'Player 1 description', 'https://www.gravatar.com/avatar/1', 'Q4YqS@example.com', 'Russia', 'Moscow'),
        (2, 'Player 2', 'Player 2 description', 'https://www.gravatar.com/avatar/2', '4M7lP@example.com', 'USA', 'New York'),
        (3, 'Player 3', 'Player 3 description', 'https://www.gravatar.com/avatar/3', 'o210aS@example.com', 'USA', 'Washington, D.C.');
GO

SELECT * FROM lab13_1_db.dbo.Player;
SELECT * FROM lab13_2_db.dbo.Player;
SELECT * FROM PlayerView;

-- UPDATE

DROP TRIGGER IF EXISTS PlayerViewUpdateTrigger;
GO

CREATE TRIGGER PlayerViewUpdateTrigger ON PlayerView
    INSTEAD OF UPDATE
    AS
        BEGIN
            IF UPDATE(PlayerID)
                THROW 50000, 'PlayerID should not be changed', 1;

            UPDATE lab13_1_db.dbo.Player
            SET PublicName = i.PublicName, Description = i.Description, AvatarURL = i.AvatarURL
            FROM lab13_1_db.dbo.Player AS P
                INNER JOIN inserted i on P.PlayerID = i.PlayerID

            UPDATE lab13_2_db.dbo.Player
            SET Email = i.Email, Country = i.Country, City = i.City
            FROM lab13_2_db.dbo.Player AS P
                 INNER JOIN inserted i on P.PlayerID = i.PlayerID
        END;
GO

UPDATE PlayerView
    SET PublicName = 'Admin', Country = 'Anon Country', City = 'Anon City'
    WHERE PublicName = 'Player 1';
GO

SELECT * FROM lab13_1_db.dbo.Player;
SELECT * FROM lab13_2_db.dbo.Player;
SELECT * FROM PlayerView;

-- DELETE

DROP TRIGGER IF EXISTS PlayerViewDeleteTrigger;
GO

CREATE TRIGGER PlayerViewDeleteTrigger ON PlayerView
    INSTEAD OF DELETE
    AS
        BEGIN
            DELETE FROM lab13_1_db.dbo.Player
            WHERE PlayerID IN (SELECT PlayerID FROM deleted);

            DELETE FROM lab13_2_db.dbo.Player
            WHERE PlayerID IN (SELECT PlayerID FROM deleted);
        END;
GO

DELETE FROM PlayerView
    WHERE PublicName = 'Player 2';
GO

SELECT * FROM lab13_1_db.dbo.Player;
SELECT * FROM lab13_2_db.dbo.Player;
SELECT * FROM PlayerView;
GO
