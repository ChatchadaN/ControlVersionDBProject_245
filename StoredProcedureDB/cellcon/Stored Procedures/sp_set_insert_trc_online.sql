-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_insert_trc_online] 
	-- Add the parameters for the stored procedure here
	 @Lotno varchar(50) = ''
	,@Quantity int = 0
	,@Process varchar(50) = ''
	,@InspType varchar(50) = ''
	,@RequestMode varchar(50) = ''
	,@RequestMode2 varchar(50) = ''
	,@RequestMode3 varchar(50) = ''
	,@InspectionItem varchar(50) = ''
	,@QuantityAdjust varchar(50) = ''
	,@NgRandom int = 0
	,@OpNo varchar(6) = ''
	,@Abnormal varchar(150) = ''
	,@InspTeceiveTime datetime = null
	,@Picture varBinary(max)
	,@McReques varchar(50)
	,@RequestCode1 varchar(50) 
	,@RequestCode2 varchar(50) 
	,@RequestCode3 varchar(50) 

	 

	
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @count_row int	,@shipment_date datetime ,@picture_id int =0
	SET NOCOUNT ON;
	
	if(@Picture is not null)
	begin
	 insert into [DBx].[dbo].[TrcPicture] (
				   [data]
				   ,[update_at]
				  )
				  values(
					 @Picture
					 ,getdate()
					 )

				 select @picture_id = @@identity
	end 

	
		select @count_row = COUNT(*) from DBx.INS.TRC where LotNo = @Lotno and McReques = @McReques
	
		if (@count_row = 0)
		begin
				insert into DBx.INS.TRC (
			   [LotNo]
			  ,[Quantity]
			  ,[Process]
			  ,[InspType]
			  ,[RequestMode]
			  ,[RequestMode2]
			  ,[RequestMode3]
			  ,[InspectionItem]
			  ,[QuantityAdjust]
			  ,[NgRandom]
			  ,[OpNo]
			  ,[RequestInspectionTime]
			  ,[Abnormal]			  
			  ,[IdPicture]
			  ,[McReques]
			  ,[RequestCode1]
			  ,[RequestCode2]
			  ,[RequestCode3]
			  

			  )
			  values(
				 @Lotno
				,@Quantity
				,@Process
				,@InspType
				,@RequestMode
				,@RequestMode2
				,@RequestMode3
				,@InspectionItem
				,@QuantityAdjust
				,@NgRandom
				,@OpNo
				,GETDATE()
				,@Abnormal			
				,@picture_id
				,@McReques
				,@RequestCode1
				,@RequestCode2
				,@RequestCode3
				)
		end 
		else if(@count_row >= 1)
		begin 
				UPDATE DBx.INS.TRC
	SET    [LotNo]	                =	@Lotno		 
		  ,[Quantity]	            =	@Quantity
		  ,[Process]	            =	@Process
		  ,[InspType]               =	@InspType
		  ,[RequestMode]            =	@RequestMode
		  ,[RequestMode2]            =	@RequestMode2
		  ,[RequestMode3]            =	@RequestMode3
		  ,[InspectionItem]	        =	@InspectionItem
		  ,[QuantityAdjust]         =	@QuantityAdjust
		  ,[NgRandom]               =	@NgRandom
		  ,[OpNo]	                =	@OpNo
		  ,[RequestInspectionTime]	=	GETDATE()
		  ,[Abnormal]	            =	@Abnormal
		  ,[IdPicture]	            =	@picture_id
		  ,[McReques]               =   @McReques
		  ,[RequestCode1]           =   @RequestCode1
		  ,[RequestCode2]            =   @RequestCode2
		  ,[RequestCode3]            =   @RequestCode3
	
	  
WHERE LotNo = @Lotno 
		end
	select @Picture

END
