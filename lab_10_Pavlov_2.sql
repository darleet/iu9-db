USE master;
GO

USE lab10_db;
GO

-- Грязное чтение
BEGIN TRANSACTION;
    UPDATE Developer
    SET DeveloperName = 'DIRTY READ'
    WHERE DeveloperID = 1;

ROLLBACK TRANSACTION;
GO

-- Невоспроизводимое чтение
BEGIN TRANSACTION;
    UPDATE Developer
    SET DeveloperName = 'NON REPEATABLE READ'
    WHERE DeveloperID = 2;
COMMIT TRANSACTION;
GO

-- Фантомное чтение
BEGIN TRANSACTION;
    INSERT INTO Developer (DeveloperName, Location, AvatarURL, WebsiteURL)
    VALUES ('PHANTOM READ', 'Detroit', 'google.com', 'steam.com');
COMMIT TRANSACTION;
GO
