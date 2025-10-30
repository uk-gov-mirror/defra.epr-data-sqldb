CREATE PROCEDURE [dbo].[sp_backup_table]
    @table_name NVARCHAR(128),
    @schema_name NVARCHAR(128) = 'dbo',
    @backup_suffix NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @backup_table_name NVARCHAR(200);
    DECLARE @full_table_name NVARCHAR(300);
    DECLARE @backup_date NVARCHAR(20);
    DECLARE @error_message NVARCHAR(4000);
    
    BEGIN TRY
        -- Validate input parameters
        IF @table_name IS NULL OR LTRIM(RTRIM(@table_name)) = ''
        BEGIN
            RAISERROR('Table name cannot be null or empty', 16, 1);
            RETURN;
        END
        
        IF @schema_name IS NULL OR LTRIM(RTRIM(@schema_name)) = ''
        BEGIN
            SET @schema_name = 'dbo';
        END
        
        -- Clean input parameters
        SET @table_name = LTRIM(RTRIM(@table_name));
        SET @schema_name = LTRIM(RTRIM(@schema_name));
        SET @full_table_name = QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name);
        
        -- Check if source table exists
        IF NOT EXISTS (
            SELECT 1 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = @schema_name 
            AND TABLE_NAME = @table_name
        )
        BEGIN
            SET @error_message = 'Table ' + @full_table_name + ' does not exist';
            RAISERROR(@error_message, 16, 1);
            RETURN;
        END
        
        -- Generate backup table name
        SET @backup_date = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
        
        IF @backup_suffix IS NOT NULL AND LTRIM(RTRIM(@backup_suffix)) != ''
        BEGIN
            SET @backup_table_name = @table_name + '_backup_' + LTRIM(RTRIM(@backup_suffix)) + '_' + @backup_date;
        END
        ELSE
        BEGIN
            SET @backup_table_name = @table_name + '_backup_' + @backup_date;
        END
        
        -- Check if backup table already exists
        IF EXISTS (
            SELECT 1 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = @schema_name 
            AND TABLE_NAME = @backup_table_name
        )
        BEGIN
            SET @error_message = 'Backup table ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@backup_table_name) + ' already exists';
            RAISERROR(@error_message, 16, 1);
            RETURN;
        END
        
        -- Create backup table with data
        SET @sql = 'SELECT * INTO ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@backup_table_name) + 
                   ' FROM ' + @full_table_name;
        
        PRINT 'Creating backup table: ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@backup_table_name);
        PRINT 'Executing SQL: ' + @sql;
        
        EXEC sp_executesql @sql;
        
        -- Get row count for confirmation
        SET @sql = 'SELECT @row_count = COUNT(*) FROM ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@backup_table_name);
        DECLARE @row_count INT;
        EXEC sp_executesql @sql, N'@row_count INT OUTPUT', @row_count OUTPUT;
        
        PRINT 'Backup completed successfully!';
        PRINT 'Source table: ' + @full_table_name;
        PRINT 'Backup table: ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@backup_table_name);
        PRINT 'Rows copied: ' + CAST(@row_count AS NVARCHAR(20));
        
    END TRY
    BEGIN CATCH
        SET @error_message = 'Error creating backup: ' + ERROR_MESSAGE();
        PRINT @error_message;
        RAISERROR(@error_message, 16, 1);
    END CATCH
END;
GO

/*
Usage Examples:

-- Basic backup with default schema (dbo)
EXEC [dbo].[sp_backup_table] @table_name = 'Organisations';

-- Backup with specific schema
EXEC [dbo].[sp_backup_table] 
    @table_name = 'Submissions', 
    @schema_name = 'rpd';

-- Backup with custom suffix
EXEC [dbo].[sp_backup_table] 
    @table_name = 'CompanyDetails', 
    @schema_name = 'rpd',
    @backup_suffix = 'before_migration';

-- This will create tables like:
-- dbo.Organisations_backup_20251030_143022
-- rpd.Submissions_backup_20251030_143022
-- rpd.CompanyDetails_backup_before_migration_20251030_143022
*/