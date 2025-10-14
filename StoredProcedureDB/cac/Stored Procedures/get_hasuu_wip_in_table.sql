-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[get_hasuu_wip_in_table] 
	-- Add the parameters for the stored procedure here
	  @package varchar(20) = ''
	, @device varchar(20) = ''
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @datetime DATETIME
	DECLARE @year_now int = 0
	SET @datetime = GETDATE()
	SELECT @year_now = (FORMAT(@datetime,'yy') - 3)

	SELECT T1.* 
		FROM (
		SELECT pk.short_name as Type_Name
				, dv.name as Device_Name 
				, dv.pcs_per_pack as Packing_Standerd_QTY
				, dv.rank_value as Rank
				, SUM(sur.pcs) as HASU_Stock_QTY
				, SUM(sur.pcs)/(dv.pcs_per_pack) as TotalReel
				, COUNT(sur.serial_no) as QtyLot
				, SUM(sur.pcs)%(dv.pcs_per_pack) as Hasuu_Total
				, pk_g.name as package_group_name
				, sur.qc_instruction as Tomson3
		   from APCSProDB.trans.surpluses as sur
		   INNER JOIN APCSProDB.trans.lots as lot on sur.lot_id = lot.id
		   INNER JOIN (
				select case when dv1.rank is null then '' else dv1.rank end As rank_value,* 
				from APCSProDB.method.device_names as dv1
		   ) as dv on lot.act_device_name_id = dv.id
		   INNER JOIN APCSProDB.method.packages as pk on dv.package_id = pk.id
		   INNER JOIN APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
		   LEFT JOIN APCSProDB.trans.locations as locat on sur.location_id = locat.id
		   WHERE (SUR.location_id IS NOT NULL and SUR.location_id != 0)
				AND (lot.wip_state = 20 OR lot.wip_state = 70 OR lot.wip_state = 100)
				AND lot.quality_state = 0
				AND sur.in_stock = 2 
				AND (SUBSTRING(sur.serial_no,1,2) >= @year_now OR sur.is_ability = 1) 
				AND sur.pcs != 0
				AND SUBSTRING(sur.serial_no,5,1) !='E' 
				AND (SUBSTRING(sur.serial_no,5,1) !='G' 
					OR (SUBSTRING(serial_no,5,1) = 'G' AND dv.name IN ('SV013-HE2           ','SV131-HE2           ','SV014-HE2           ','SV010-HE2           ','BV2HC045EFU-C       ','BV2HD045EFU-CE2     ','BV2HD070EFU-CE2    ','BV2HC045EFU-CE2     ')) 
					) 
		   GROUP BY pk.short_name,dv.name,dv.rank_value,dv.pcs_per_pack,pk_g.name,sur.qc_instruction
		   Having SUM(sur.pcs) >= dv.pcs_per_pack 
				AND SUM(sur.pcs)/(NULLIF(dv.pcs_per_pack, 0)) >= 1
		) AS T1
	WHERE T1.Type_Name LIKE @package AND T1.Device_Name LIKE @device

END
