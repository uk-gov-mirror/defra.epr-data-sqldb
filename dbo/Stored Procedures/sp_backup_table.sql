-- For Azure Synapse Analytics / SQL Server PDW
-- Using CREATE TABLE AS SELECT (CTAS) instead of stored procedure

-- Script to create backup table (replace parameters manually)
DECLARE @table_name NVARCHAR(128) = '[TABLE_NAME]';          -- Replace with actual table name
DECLARE @schema_name NVARCHAR(128) = '[SCHEMA_NAME]';        -- Replace with actual schema name
DECLARE @backup_suffix NVARCHAR(50) = '[BACKUP_SUFFIX]';     -- Replace with suffix or leave empty

DECLARE @backup_table_name NVARCHAR(200);
DECLARE @backup_date NVARCHAR(20);
DECLARE @sql NVARCHAR(MAX);

-- Generate backup table name with timestamp
SET @backup_date = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(20), GETDATE(), 126), '-', ''), ':', ''), 'T', '_');
SET @backup_date = LEFT(@backup_date, 15); -- yyyyMMdd_HHmmss format

IF @backup_suffix IS NOT NULL AND @backup_suffix != '[BACKUP_SUFFIX]' AND LTRIM(RTRIM(@backup_suffix)) != ''
BEGIN
    SET @backup_table_name = @table_name + '_backup_' + @backup_suffix + '_' + @backup_date;
END
ELSE
BEGIN
    SET @backup_table_name = @table_name + '_backup_' + @backup_date;
END

-- Create the backup table using CTAS (Create Table As Select)
SET @sql = 'CREATE TABLE ' + @schema_name + '.' + @backup_table_name + ' 
WITH (
    DISTRIBUTION = HASH([SubmissionId]),  -- Adjust distribution column as needed
    CLUSTERED COLUMNSTORE INDEX
)
AS SELECT * FROM ' + @schema_name + '.' + @table_name;

PRINT 'Creating backup with SQL: ' + @sql;
-- EXEC sp_executesql @sql;  -- Uncomment to execute

/*
Manual Usage Examples (replace the DECLARE values above):

1. Basic backup:
   SET @table_name = 'Organisations';
   SET @schema_name = 'dbo';
   SET @backup_suffix = '[BACKUP_SUFFIX]'; -- Leave as is for no suffix

2. With schema:
   SET @table_name = 'Submissions';
   SET @schema_name = 'rpd';
   SET @backup_suffix = '[BACKUP_SUFFIX]';

3. With custom suffix:
   SET @table_name = 'CompanyDetails';
   SET @schema_name = 'rpd';
   SET @backup_suffix = 'before_migration';

Note: You may need to adjust the DISTRIBUTION column based on your source table structure.
Common distribution columns in this database: SubmissionId, OrganisationId, FileId
*/
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