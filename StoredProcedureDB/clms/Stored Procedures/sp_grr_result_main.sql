-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [clms].[sp_grr_result_main]
@grr_id int,
@chk_at varchar(10),
@sec_id int,
@do_user int,
@chk_user int,
@eq_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)
    -- Insert statements for procedure here
	set @SQLQuery ='SELECT        grr.grr_id, eq.eq_name, eq.eq_num, APCSProDB.ctrlic.ref_value.ref_desc AS model, ref_value_1.ref_desc AS check_topic, grr.prod_name, ref_value_2.ref_desc AS chk_methode, 
                         grr.err_val_desc, grr.err_val, grr.chk_at, grr.grr_val, grr.ndc_val, grr.grr_tol, grr.grr_tv, grr.xabar, grr.rabar, grr.xbbar, grr.rbbar, 
                         grr.xcbar, grr.rcbar, grr.xbar, grr.rp, grr.rbar, grr.xdiff, grr.grr_accep_status, grr.k1, grr.k2, grr.k3, grr.ev, grr.ev_tol, 
                         grr.ev_tv, grr.av, grr.av_tol, grr.av_tv, grr.pv, grr.pv_tol, grr.pv_tv, grr.tv, users_1.name AS chk_user1, APCSProDB.man.users.name AS chk_user2, 
                         users_2.name AS chk_user3, grd.val1 AS avg_total_1, grd.val2 AS avg_total_2, grd.val3 AS avg_total_3, grd.val4 AS avg_total_4, 
                         grd.val5 AS avg_total_5, grd.val6 AS avg_total_6, grd.val7 AS avg_total_7, grd.val8 AS avg_total_8, grd.val9 AS avg_total_9, 
                         grd.val10 AS avg_total_10, grr.min_pass, grr.min_pass_cond, grr.max_pass_cond, grr.max_not_pass, grr.max_ndc

FROM           APCSProDB.man.users AS users_1 RIGHT OUTER JOIN
                         APCSProDB.clms.cb_equip as eq RIGHT OUTER JOIN
                         APCSProDB.ctrlic.ref_value AS ref_value_2 RIGHT OUTER JOIN
                         APCSProDB.clms.cb_grr as grr INNER JOIN
                         APCSProDB.clms.cb_grr_detail as grd ON grr.grr_id = grd.grr_id AND grd.seq_title = ''AVGTOTAL'' ON ref_value_2.ref_id = grr.chk_method ON 
                         eq.eq_id = grr.eq_id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_2 ON grr.chk3_user = users_2.id LEFT OUTER JOIN
                         APCSProDB.man.users ON grr.chk2_user = APCSProDB.man.users.id ON users_1.id = grr.chk1_user LEFT OUTER JOIN
                         APCSProDB.ctrlic.ref_value AS ref_value_1 ON grr.chk_topic = ref_value_1.ref_id LEFT OUTER JOIN
                         APCSProDB.ctrlic.ref_value ON eq.qe_model_id = APCSProDB.ctrlic.ref_value.ref_id WHERE 1=1 '

IF @eq_id IS NOT NULL AND @eq_id > 0
	SET @SQLQuery = @SQLQuery + ' And (eq.eq_id  = @eq_id)'

IF @grr_id IS NOT NULL AND @grr_id > 0
	SET @SQLQuery = @SQLQuery + ' And (grr.grr_id  = @grr_id)'

IF @chk_at IS NOT NULL AND @chk_at <> ''
	SET @SQLQuery = @SQLQuery + ' And (cast(grr.chk_at as date) = @chk_at)'

IF @sec_id IS NOT NULL  AND @sec_id > 0
	SET @SQLQuery = @SQLQuery + ' And (grr.sec_id = @sec_id)'

IF @do_user IS NOT NULL AND @do_user > 0
	SET @SQLQuery = @SQLQuery + ' And (grr.do_user = @do_user)'

IF @chk_user IS NOT NULL  AND @chk_user > 0
	SET @SQLQuery = @SQLQuery + ' And (grr.chk1_user = @chk_user OR grr.chk2_user = @chk_user OR grr.chk3_user = @chk_user   )'



SET @ParamDefinition = '@grr_id int,
@chk_at varchar(10),
@sec_id int,
@do_user int,
@chk_user int,
@eq_id int'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@grr_id,
@chk_at,
@sec_id,
@do_user,
@chk_user,
@eq_id    

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)
END

