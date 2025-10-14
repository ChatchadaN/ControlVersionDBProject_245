-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_BM_Daily_Report]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>

	--GETDATE() date 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>

	
		
  INSERT INTO [DBx].[dbo].[BM_Daily_Report] 
	([Date1]
      ,[TE1_Remain]
      ,[TE1_BM_Occure]
      ,[TE1_BM_Finish]
      ,[TE1_BM_Remain]
      ,[TE1_MTTR]
      ,[TE2_Remain]
      ,[TE2_BM_Occure]
      ,[TE2_BM_Finish]
      ,[TE2_BM_Remain]
      ,[TE2_MTTR]
      ,[TE1_Stop]
      ,[TE2_Stop]
	  ,[Day_Remain]
      ,[Day_Occure]
      ,[Day_Finish]
      ,[Day_BM_Remain]
      ,[Night_Remain]
      ,[Night_Occure]
      ,[Night_Finish]
      ,[Night_BM_Remain]
	  ,[TE1_Wait_Time]
      ,[TE2_Wait_Time]
	)
	VALUES 

	(
	(select dateadd(day, datediff(day, 0,GETDATE())-1, 0)),
	(select [TE1_Remain] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-2, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1))),
	(select [TE1_Occure] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1))),
	(select [TE1_Finish] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1)  )),
	(select [TE1_BM_Remain] = abs((select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-2, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1))+(select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1))-(select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1)  )) ),
	(select [TE1_MTTR] = (select MTTR = SUM( DATEDIFF(MINUTE,TimeStart,TimeFinish)) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and (TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00')
and Floor in (1))),
	(select [TE2_Remain] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-2, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (2))),
	(select [TE2_Occure] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (2))),
	(select [TE2_Finish] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (2)  )),
	(select [TE2_BM_Remain] = abs((select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-2, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (2))+(select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (2))-(select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (2)  )) ),
	(select [TE2_MTTR] = (select SUM( DATEDIFF(MINUTE,TimeStart,TimeFinish)) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and (TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00')
and Floor in (2))),
	(select [TE1_Stop] = (select Stop_Time = SUM( DATEDIFF(MINUTE,TimeRequest,TimeFinish)) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and (TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00')
and Floor in (1) )),
	(select [TE2_Stop] = (select Stop_Timete2 = SUM( DATEDIFF(MINUTE,TimeRequest,TimeFinish)) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and (TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00')
and Floor in (2) )),
	(select [Day_Remain] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-2, 0) + '20:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00'
and Floor in (1,2)  ) ),
	(select [Day_Occure] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00'
and Floor in (1,2)  ) ),
	(select [Day_Finish] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00'
and Floor in (1,2)  )),
	(select [Day_BM_Remain] = abs((select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-2, 0) + '20:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00'
and Floor in (1,2)  ) + (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00'
and Floor in (1,2)  )-(select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00'
and Floor in (1,2)  ))),
	(select [Night_Remain] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1,2)  )),
	(select [Night_Occure] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1,2)  ) ),
	(select  [Night_Finish] = (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1,2)  )),
	(select [Night_BM_Remain] = abs((select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1,2)  ) + (select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeRequest between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1,2)  )-(select count(1) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '20:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00'
and Floor in (1,2)  ))),
	(select [TE1_Wait_Time] = (select TE1_Wait_Time = SUM( DATEDIFF(MINUTE,TimeRequest,TimeStart)) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and (TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00')
and Floor in (1))),
	(select [TE2_Wait_Time] = (select TE1_Wait_Time = SUM( DATEDIFF(MINUTE,TimeRequest,TimeStart)) from dbx.dbo.BMMaintenance a
inner join dbx.dbo.BMPackage b
on a.PMID = b.PMID and a.Package = b.Description
where a.PMID ='11' and StatusID <> '5'
and (TimeFinish between dateadd(day, datediff(day, 0,GETDATE())-1, 0) + '08:00' and dateadd(day, datediff(day, 0,GETDATE()), 0) + '08:00')
and Floor in (2))
)
)
	
	
END
