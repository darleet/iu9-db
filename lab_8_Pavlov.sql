USE master;
GO

IF DB_ID (N'lab8_db') IS NOT NULL
    DROP DATABASE lab8_db;
GO

-- Создание базы

CREATE DATABASE lab8_db
    ON (
    NAME = lab8_dat,
    FILENAME = N'/var/opt/mssql/data/lab8_dat.mdf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
    LOG ON (
    NAME = lab8_log,
    FILENAME = N'/var/opt/mssql/data/lab8_log.ldf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
    )
GO

USE lab8_db;
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

INSERT INTO Game
(GameName, ReleaseDate, Description, Price, DeveloperID)
VALUES
    ('The Legend of Zelda: Breath of the Wild', '2017-03-03', 'The Legend of Zelda: Breath of the Wild is an action-adventure game', 199.99, 1),
    ('Super Mario Odyssey', '2017-10-27', 'Super Mario Odyssey is an action-adventure game', 299.99, 1),
    ('Super Mario 64', '1996-09-21', 'Super Mario 64 is an action-adventure game', 59.99, 1),
    ('Super Smash Bros. Ultimate', '2018-10-26', 'Super Smash Bros. Ultimate is an action-adventure game', 59.99, 2),
    ('Super Mario 3D World', '2013-11-21', 'Super Mario 3D World is an action-adventure game', 59.99, 2);
GO

-- процедура, возвращающая курсор

CREATE PROCEDURE GetCursorGame
    @Result CURSOR VARYING OUTPUT
AS
BEGIN
    SET @Result = CURSOR SCROLL FOR
        SELECT GameName, ReleaseDate, Description, Price
        FROM Game;
    OPEN @Result;
END;
GO

BEGIN
    DECLARE @Cursor CURSOR;
    EXEC GetCursorGame @Result = @Cursor OUTPUT;

    DECLARE @GameName NVARCHAR(255);
    DECLARE @ReleaseDate DATE;
    DECLARE @Description NVARCHAR(1023);
    DECLARE @Price DECIMAL(9, 2);

    FETCH NEXT FROM @Cursor INTO @GameName, @ReleaseDate, @Description, @Price;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'Название игры: ' + @GameName + N', дата релиза: ' + CAST(@ReleaseDate AS NVARCHAR) +
            N', описание: ' + @Description + N', цена: ' + CAST(@Price AS NVARCHAR);
        FETCH NEXT FROM @Cursor INTO @GameName, @ReleaseDate, @Description, @Price;
    END;

    CLOSE @Cursor;
    DEALLOCATE @Cursor;
END;
GO

-- с формированием столбца пользовательской функцией

CREATE FUNCTION IncreasePrice (@Price DECIMAL(9, 2))
    RETURNS DECIMAL(9, 2)
AS
BEGIN
    RETURN @Price * 1.1;
END;
GO

CREATE PROCEDURE GetCursorGameWithIncreasedPrice
    @Result CURSOR VARYING OUTPUT
AS
BEGIN
    SET @Result = CURSOR SCROLL FOR
        SELECT GameName, ReleaseDate, Description, dbo.IncreasePrice(Price) AS Price
        FROM Game;
    OPEN @Result;
END;
GO

BEGIN
    DECLARE @Cursor CURSOR;
    EXEC GetCursorGameWithIncreasedPrice @Result = @Cursor OUTPUT;

    DECLARE @GameName NVARCHAR(255);
    DECLARE @ReleaseDate DATE;
    DECLARE @Description NVARCHAR(1023);
    DECLARE @Price DECIMAL(9, 2);

    FETCH NEXT FROM @Cursor INTO @GameName, @ReleaseDate, @Description, @Price;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'Название игры: ' + @GameName + N', дата релиза: ' + CAST(@ReleaseDate AS NVARCHAR) +
            N', описание: ' + @Description + N', цена: ' + CAST(@Price AS NVARCHAR);
        FETCH NEXT FROM @Cursor INTO @GameName, @ReleaseDate, @Description, @Price;
    END;

    CLOSE @Cursor;
    DEALLOCATE @Cursor;
END;
GO

-- прокрутка курсора

CREATE FUNCTION IsExpensive (@Price DECIMAL(9, 2))
    RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT;
    IF @Price > 100
        SET @Result = 1;
    ELSE
        SET @Result = 0;
    RETURN @Result;
END;
GO

CREATE PROCEDURE GetExpensiveGames
AS
BEGIN
    DECLARE @Cursor CURSOR;
    EXEC GetCursorGame @Result = @Cursor OUTPUT;

    DECLARE @GameName NVARCHAR(255);
    DECLARE @ReleaseDate DATE;
    DECLARE @Description NVARCHAR(1023);
    DECLARE @Price DECIMAL(9, 2);

    -- сама прокрутка
    FETCH FIRST FROM @Cursor INTO @GameName, @ReleaseDate, @Description, @Price;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF dbo.IsExpensive(@Price) = 1
            PRINT N'Название игры: ' + @GameName + N', дата релиза: ' + CAST(@ReleaseDate AS NVARCHAR) +
                N', описание: ' + @Description + N', цена: ' + CAST(@Price AS NVARCHAR);

        FETCH NEXT FROM @Cursor INTO @GameName, @ReleaseDate, @Description, @Price;
    END;

    CLOSE @Cursor;
    DEALLOCATE @Cursor;
END;
GO

EXEC GetExpensiveGames;
GO

-- с табличной функцией

CREATE FUNCTION GameWithIncreasedPrice()
    RETURNS @ResultTable TABLE (GameName NVARCHAR(255), ReleaseDate DATE,
                                Description NVARCHAR(255), Price DECIMAL(9, 2))
AS
    BEGIN
        INSERT INTO @ResultTable (GameName, ReleaseDate, Description, Price)
            SELECT GameName, ReleaseDate, Description, dbo.IncreasePrice(Price) AS Price
            FROM Game;
        RETURN;
    END;
GO

CREATE FUNCTION GameWithIncreasedPriceV2()
    RETURNS TABLE
AS
    RETURN (
        SELECT GameName, ReleaseDate, Description, dbo.IncreasePrice(Price) AS Price
        FROM Game
    );
GO

CREATE PROCEDURE GetCursorGameWithIncreasedPriceTable
@Result CURSOR VARYING OUTPUT
AS
BEGIN
    SET @Result = CURSOR SCROLL FOR
        SELECT * FROM dbo.GameWithIncreasedPrice();
    OPEN @Result;
END;
GO

BEGIN
    DECLARE @Cursor CURSOR;
    EXEC GetCursorGameWithIncreasedPriceTable @Result = @Cursor OUTPUT;

    DECLARE @GameName NVARCHAR(255);
    DECLARE @ReleaseDate DATE;
    DECLARE @Description NVARCHAR(1023);
    DECLARE @Price DECIMAL(9, 2);

    FETCH NEXT FROM @Cursor INTO @GameName, @ReleaseDate, @Description, @Price;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT N'Название игры: ' + @GameName + N', дата релиза: ' + CAST(@ReleaseDate AS NVARCHAR) +
                  N', описание: ' + @Description + N', цена: ' + CAST(@Price AS NVARCHAR);
            FETCH NEXT FROM @Cursor INTO @GameName, @ReleaseDate, @Description, @Price;
        END;

    CLOSE @Cursor;
    DEALLOCATE @Cursor;
END;
GO

