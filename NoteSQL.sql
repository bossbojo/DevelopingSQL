CREATE TRIGGER [MRP].Update_Report_ProductPlan
	ON [MRP].[PL_DocNo]
	FOR UPDATE
	AS
	BEGIN
		SET NOCOUNT ON
		DECLARE @status_ct_new AS CHAR(2)
		DECLARE @status_sc_new AS CHAR(2)
		DECLARE @status_sl_new AS CHAR(2)
		DECLARE @status_sw_new AS CHAR(2)

		DECLARE @status_ct_old AS CHAR(2)
		DECLARE @status_sc_old AS CHAR(2)
		DECLARE @status_sl_old AS CHAR(2)
		DECLARE @status_sw_old AS CHAR(2)
		DECLARE @plan_id AS INT
		
		SELECT 
			@status_ct_new = i.status_ct,
			@status_sc_new = i.status_sc,
			@status_sl_new = i.status_sl,
			@status_sw_new = start_date_sw,
			@plan_id = i.plan_id 
		FROM Inserted AS i

		SELECT 
			@status_ct_old = d.status_ct,
			@status_sc_old = d.status_sc,
			@status_sl_old = d.status_sl,
			@status_sw_old = d.status_sw 
		FROM Deleted AS d

		IF(@status_ct_new<>@status_ct_old)
			BEGIN
				UPDATE [sum].Report_ProductPlan 
					SET 
						status_ct =  [MRP].[sf_GetStatusDocOfPlan] (@plan_id, 'CT') ,
						ct_last_transfer = GETDATE()
					WHERE plan_id = @plan_id
			END
		
		IF(@status_sc_new<>@status_sc_old)
			BEGIN
				UPDATE [sum].Report_ProductPlan 
					SET 
						status_sc =  [MRP].[sf_GetStatusDocOfPlan] (@plan_id, 'SC') ,
						sc_last_transfer = GETDATE()
						WHERE plan_id = @plan_id
			END

		IF(@status_sl_new<>@status_sl_old)
			BEGIN
				UPDATE [sum].Report_ProductPlan 
					SET 
						status_sl =  [MRP].[sf_GetStatusDocOfPlan] (@plan_id, 'SL'),
						sl_last_transfer = GETDATE()
						WHERE plan_id = @plan_id
			END
		IF(@status_sw_new<>@status_sw_old)
			BEGIN
				UPDATE [sum].Report_ProductPlan 
					SET 
						status_sw =  [MRP].[sf_GetStatusDocOfPlan] (@plan_id, 'SW'),
						sw_last_transfer = GETDATE()  
						WHERE plan_id = @plan_id
			END
	END



CREATE TABLE [sum].[Report_ProductPlan] (
    [plan_id]          INT      NOT NULL,
    [status_ct]        CHAR (2) NULL,
    [status_sc]        CHAR (2) NULL,
    [status_sl]        CHAR (2) NULL,
    [status_pp]        CHAR (2) NULL,
    [status_sw]        CHAR (2) NULL,
    [ct_last_transfer] DATE     NULL,
    [sc_last_transfer] DATE     NULL,
    [sl_last_transfer] DATE     NULL,
    [pp_last_transfer] DATE     NULL,
    [sw_last_transfer] DATE     NULL,
    PRIMARY KEY CLUSTERED ([plan_id] ASC)
);

CREATE View MRP.v_PlanUpperStatus
AS
SELECT
	pp.status,
	MRP.f_convert_sataus(pp.status) as status_full,
	pp.plan_id,
	CONCAT('PL-',pp.plan_no) AS plan_no,
	f_pp.work_name AS work_type_name,
	f_pp.work_type_id,
	f_pp.load_date,
	[MRP].f_GetModelAndColorByPlanID(pp.plan_id) as model,
	(SELECT SUM(p.amount) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id) as amount,
	(SELECT SUM(p.done) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id) as done,
	(SELECT SUM(p.waste) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id) as waste,
	-----------CT
	rpp.status_ct AS production_ct,
	f_pp.cutting_finish AS cutting_start,
	rpp.ct_last_transfer AS finished_date_ct,
	(SELECT SUM(p.done) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id AND p.work_type = 1) as done_ct,
	(SELECT SUM(p.waste) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id AND p.work_type = 1) as waste_ct,
	-----------SC
    rpp.status_sc AS production_sc,
	f_pp.screen_finish as screen_start,
	rpp.sc_last_transfer AS finished_date_sc,
	(SELECT SUM(p.done) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id AND p.work_type = 2) as done_sc,
	(SELECT SUM(p.waste) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id AND p.work_type = 2) as waste_sc,
	-----------SL
	rpp.status_sl AS production_sl,
	f_pp.seal_finish as seal_start,
	rpp.sl_last_transfer AS finished_date_sl,
	(SELECT SUM(p.done) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id AND p.work_type = 3) as done_sl,
	(SELECT SUM(p.waste) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id AND p.work_type = 3) as waste_sl,
	-----------PP
	rpp.status_pp AS production_pp,
	f_pp.prep_finish AS prep_start,
	rpp.pp_last_transfer AS finished_date_pp,
	(SELECT SUM(p.done) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id AND p.work_type = 4) as done_pp,
	(SELECT SUM(p.waste) AS t FROM MRP.v_WorkTransfer p WHERE p.plan_id = pp.plan_id AND p.work_type = 4) as waste_pp,
	-----------SW
	rpp.status_sw AS production_sw,
	f_pp.sewing_finish AS sewing_start,
	rpp.sw_last_transfer AS finished_date_sw,
	(SELECT SUM(p.done) AS t FROM MRP.PL_Task_Sewing p WHERE p.prd_line_id = pp.prd_line_id ) as done_sw,
	(SELECT SUM(p.waste) AS t FROM MRP.PL_Task_Sewing p WHERE p.prd_line_id = pp.prd_line_id ) as waste_sw,
	(SELECT SUM(p.missing) AS t FROM MRP.PL_Task_Sewing p WHERE p.prd_line_id = pp.prd_line_id ) as missing_sw
from MRP.ProductionPlan pp
CROSS APPLY [MRP].f_FindFastLoadDate_ByPlanID(pp.plan_id) AS f_pp
INNER JOIN sum.Report_ProductPlan AS rpp ON rpp.plan_id = pp.plan_id
INNER JOIN MRP.Work_Type AS wt ON wt.work_type_id = f_pp.work_type_id
WHERE pp.status != 'C'



