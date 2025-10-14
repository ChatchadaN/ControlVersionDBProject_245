-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_records_excel_ver001] 
	-- Add the parameters for the stored procedure here
	@start_date varchar(16), @end_date varchar(16),@rackName varchar(5), @pkg varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @now datetime

    -- Insert statements for procedure here

	SELECT @now = GETDATE()

	SELECT lot_no AS LotNo
	      ,CASE WHEN (pkg.name is null)		THEN '' ELSE pkg.name		END	AS Package
		  ,CASE WHEN (dev.name is null)		THEN '' ELSE dev.name		END	AS Device
		  ,CASE WHEN (loca.name is null)	THEN '' ELSE loca.name		END	AS RackName
		  ,CASE WHEN (loca.address is null)	THEN '' ELSE loca.address	END	AS Address
		  --,CASE WHEN (CONVERT (varchar, rec.update_at_in, 20) is null)	
				--						    THEN '' ELSE CONVERT (varchar, rec.update_at_in, 20)	END AS In_Time
		  --,CASE WHEN (CONVERT (varchar, rec.update_at_out, 20) is null)
				--						    THEN '' ELSE CONVERT (varchar, rec.update_at_out, 20)	END AS Out_Time
		  ,CASE WHEN (op1.emp_num is null)	THEN '' ELSE op1.emp_num	END AS In_By
		  --,CASE WHEN (op2.emp_num is null)	THEN '' ELSE op2.emp_num	END	AS Out_By
		  --,(CASE
		  --		WHEN rec.update_at_out IS NULL		THEN CONVERT (varchar, @now - update_at_in, 24)
		  --		WHEN rec.update_at_out IS NOT NULL	THEN CONVERT (varchar, update_at_out - update_at_in, 24)
		  --  END) AS HHmmss
		  --,(CASE
		  --		WHEN rec.update_at_out IS NULL		THEN FORMAT((SELECT DATEDIFF(MINUTE, update_at_in, @now))/60.0, 'N2')
		  --		WHEN rec.update_at_out IS NOT NULL	THEN FORMAT((SELECT DATEDIFF(MINUTE, update_at_in, update_at_out))/60.0, 'N2')
		  --  END) AS Hrs
		  ,rec.recorded_at AS Timein
		  ,(CASE
			WHEN rec.record_class = 0 THEN 'ERROR'
			WHEN rec.record_class = 1 THEN 'In Rack' 
			WHEN rec.record_class = 2 THEN 'Reserved Rack'
			WHEN rec.record_class = 3 THEN 'Out Rack'
	    END) AS Reason
		,departments.name AS Dep_Name 
		,sections.name AS Sect_Name
	FROM DBx.dbo.rcs_process_records as rec
	JOIN APCSProDB.trans.lots as lot ON lot.id = rec.lot_id
	JOIN APCSProDB.trans.locations as loca ON loca.id = rec.location_id
	JOIN APCSProDB.method.packages as pkg ON lot.act_package_id = pkg.id
	JOIN APCSProDB.method.device_names as dev ON lot.act_device_name_id = dev.id
	LEFT JOIN APCSProDB.man.users as op1 ON op1.id = rec.recorded_by
	LEFT JOIN [APCSProDB].[man].[user_organizations] ON op1.id = [user_organizations].[user_id]
	LEFT JOIN [APCSProDB].[man].[organizations] ON [user_organizations].[organization_id] = [organizations].[id]
	LEFT JOIN [APCSProDB].[man].[headquarters] ON [organizations].[headquarter_id] = [headquarters].[id]
	LEFT JOIN [APCSProDB].[man].[factories] ON [headquarters].[factory_id] = [factories].[id]
	LEFT JOIN [APCSProDB].[man].[sections] ON [organizations].[section_id] = [sections].[id]
	LEFT JOIN [APCSProDB].[man].[departments] ON ([sections].[department_id] = [departments].[id] OR [organizations].[department_id] = [departments].[id])
	LEFT JOIN [APCSProDB].[man].[divisions] ON ([departments].[division_id] = [divisions].[id] OR [organizations].[division_id] = [divisions].[id])
	WHERE recorded_at BETWEEN @start_date AND @end_date
	AND loca.name like '%' + @rackName + '%'
	AND pkg.name like '%' + @pkg + '%'

	ORDER BY LotNo, RackName
END
