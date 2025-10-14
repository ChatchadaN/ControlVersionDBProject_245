CREATE TABLE [trans].[lots] (
    [id]                      INT           NOT NULL,
    [lot_no]                  CHAR (20)     NOT NULL,
    [product_family_id]       INT           NOT NULL,
    [act_package_id]          INT           NULL,
    [act_device_name_id]      INT           NOT NULL,
    [device_slip_id]          INT           NOT NULL,
    [order_id]                INT           NULL,
    [step_no]                 INT           NOT NULL,
    [act_process_id]          INT           NULL,
    [act_job_id]              INT           NULL,
    [qty_in]                  INT           NULL,
    [qty_pass]                INT           NULL,
    [qty_fail]                INT           NULL,
    [qty_last_pass]           INT           NULL,
    [qty_last_fail]           INT           NULL,
    [qty_pass_step_sum]       INT           NULL,
    [qty_fail_step_sum]       INT           NULL,
    [qty_divided]             INT           NULL,
    [qty_hasuu]               INT           NULL,
    [qty_out]                 INT           NULL,
    [is_exist_work]           TINYINT       NOT NULL,
    [in_plan_date_id]         INT           NOT NULL,
    [out_plan_date_id]        INT           NOT NULL,
    [master_lot_id]           INT           NOT NULL,
    [depth]                   SMALLINT      NOT NULL,
    [sequence]                SMALLINT      NOT NULL,
    [wip_state]               TINYINT       NOT NULL,
    [process_state]           TINYINT       NOT NULL,
    [quality_state]           TINYINT       NOT NULL,
    [first_ins_state]         TINYINT       NULL,
    [final_ins_state]         TINYINT       NULL,
    [is_special_flow]         TINYINT       NOT NULL,
    [special_flow_id]         INT           NULL,
    [is_temp_devided]         TINYINT       NOT NULL,
    [temp_devided_count]      TINYINT       NULL,
    [product_class_id]        TINYINT       NOT NULL,
    [priority]                TINYINT       NOT NULL,
    [finish_date_id]          INT           NULL,
    [finished_at]             DATETIME      NULL,
    [in_date_id]              INT           NULL,
    [in_at]                   DATETIME      NULL,
    [ship_date_id]            INT           NULL,
    [ship_at]                 DATETIME      NULL,
    [modify_out_plan_date_id] INT           NOT NULL,
    [modified_at]             DATETIME      NULL,
    [modified_by]             INT           NULL,
    [location_id]             INT           NULL,
    [acc_location_id]         INT           NULL,
    [machine_id]              INT           NULL,
    [container_no]            VARCHAR (20)  NULL,
    [std_time_sum]            INT           NULL,
    [start_step_no]           INT           NOT NULL,
    [m_no]                    VARCHAR (50)  NULL,
    [qc_comment_id]           INT           NULL,
    [qc_memo_id]              INT           NULL,
    [pass_plan_time]          DATETIME      NULL,
    [pass_plan_time_up]       DATETIME      NULL,
    [process_job_id]          INT           NULL,
    [origin_material_id]      INT           NULL,
    [carried_at]              DATETIME      NULL,
    [is_imported]             TINYINT       NULL,
    [is_label_issued]         TINYINT       NULL,
    [held_at]                 DATETIME      NULL,
    [held_minutes_current]    INT           NULL,
    [created_at]              DATETIME      NULL,
    [created_by]              INT           NULL,
    [updated_at]              DATETIME      NULL,
    [updated_by]              INT           NULL,
    [limit_time_state]        TINYINT       NULL,
    [map_edit_state]          TINYINT       NULL,
    [qty_frame_in]            INT           NULL,
    [qty_frame_pass]          INT           NULL,
    [qty_frame_fail]          INT           NULL,
    [qty_frame_last_pass]     INT           NULL,
    [qty_frame_last_fail]     INT           NULL,
    [qty_frame_pass_step_sum] INT           NULL,
    [qty_frame_fail_step_sum] INT           NULL,
    [carrier_no]              VARCHAR (20)  NULL,
    [next_carrier_no]         VARCHAR (20)  NULL,
    [production_category]     TINYINT       NULL,
    [partition_no]            INT           NULL,
    [using_material_spec]     VARCHAR (20)  NULL,
    [start_manufacturing_at]  DATETIME      NULL,
    [plan_input_chip]         INT           NULL,
    [qty_combined]            INT           NULL,
    [reprint_count]           SMALLINT      NULL,
    [external_lot_no]         VARCHAR (50)  NULL,
    [is_3h]                   TINYINT       NULL,
    [qty_p_nashi]             INT           NULL,
    [qty_front_ng]            INT           NULL,
    [qty_marker]              INT           NULL,
    [qty_cut_frame]           INT           NULL,
    [is_temp_divided]         TINYINT       NULL,
    [temp_divided_count]      TINYINT       NULL,
    [next_sideway_step_no]    INT           NULL,
    [guarantee_lot_id]        INT           NULL,
    [e_slip_id]               VARCHAR (50)  NULL,
    [pc_instruction_code]     INT           NULL,
    [qty_fail_details]        VARCHAR (255) NULL,
    CONSTRAINT [PK_lots] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_lots_device_id]
    ON [trans].[lots]([act_device_name_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_lots_device_slip_step_id]
    ON [trans].[lots]([device_slip_id] ASC, [step_no] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_lots_e_slip_id]
    ON [trans].[lots]([e_slip_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_lots_lotno]
    ON [trans].[lots]([lot_no] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_lots_packageid]
    ON [trans].[lots]([act_package_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_lots_wip_id]
    ON [trans].[lots]([wip_state] ASC)
    INCLUDE([device_slip_id], [act_package_id], [act_device_name_id], [order_id]);

