-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[BackupTable_aaa]
AS
BEGIN
    DECLARE @BackupFileName NVARCHAR(255)
    SET @BackupFileName = 'e:\backup_Table\wip_test' + CONVERT(NVARCHAR, GETDATE(), 112) + '.bak'

    -- สำรองข้อมูลตาราง aaa
    SELECT * INTO aaa_backup
    FROM DWH.cac.wip_test
	 --SELECT *
  --  FROM DWH.cac.wip_test
    -- สำรองข้อมูลไปยังไฟล์
    --BACKUP DATABASE YourDatabase
    --TO DISK = @BackupFileName
    --WITH FORMAT,
    --     NAME = 'aaa Backup',
    --     DESCRIPTION = 'Backup of aaa on ' + CONVERT(NVARCHAR, GETDATE(), 120)
END

