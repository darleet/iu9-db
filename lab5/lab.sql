USE master;
GO

IF DB_ID (N'lab5_db') IS NOT NULL
    DROP DATABASE lab5_db;
GO

-- Создание базы

CREATE DATABASE lab5_db
    ON (
        NAME = lab5_dat,
        FILENAME = N'/var/opt/mssql/data/lab5_dat.mdf',
        SIZE = 5MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 5MB
    )
    LOG ON (
        NAME = lab5_log,
        FILENAME = N'/var/opt/mssql/data/lab5_log.ldf',
        SIZE = 5MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 5MB
    )
GO

USE lab5_db;
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

-- Создание файловой группы

ALTER DATABASE lab5_db
    ADD FILEGROUP new_fg;
GO

ALTER DATABASE lab5_db
    ADD FILE (
        NAME = lab5_dat_extra,
        FILENAME = N'/var/opt/mssql/data/lab5_dat_extra.ndf',
        SIZE = 5MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 5MB
    ) TO FILEGROUP new_fg;
GO

ALTER DATABASE lab5_db
    MODIFY FILEGROUP new_fg DEFAULT;
GO

-- Новая таблица

CREATE TABLE Game (
    GameID INT IDENTITY(1, 1) NOT NULL,
    GameName NVARCHAR(255) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Description NVARCHAR(1023),
    Price DECIMAL(9, 2) NOT NULL,
    DeveloperID INT NOT NULL,
    CONSTRAINT AK_GameName_ReleaseDate UNIQUE (GameName, ReleaseDate),
    CONSTRAINT PK_Game PRIMARY KEY CLUSTERED (GameID),
    FOREIGN KEY (DeveloperID) REFERENCES Developer(DeveloperID),
)
GO

-- Перенос Game при помощи clustered index

ALTER TABLE Game
    DROP CONSTRAINT PK_Game, AK_GameName_ReleaseDate;
GO

CREATE CLUSTERED INDEX IX_Game_GameID
    ON Game(GameID)
    ON [PRIMARY];
GO

ALTER DATABASE lab5_db
    MODIFY FILEGROUP [PRIMARY] DEFAULT;
GO

ALTER DATABASE lab5_db
    REMOVE FILE lab5_dat_extra;
GO

ALTER DATABASE lab5_db
    REMOVE FILEGROUP new_fg;
GO

-- Создание схемы

CREATE SCHEMA lab5_schema;
GO

ALTER SCHEMA lab5_schema TRANSFER Game;
GO

ALTER SCHEMA dbo TRANSFER lab5_schema.Game;
GO

DROP SCHEMA lab5_schema;
GO

