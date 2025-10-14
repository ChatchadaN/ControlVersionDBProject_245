CREATE VIEW dbo.view_scheduler_operation_record_base_v03
AS
SELECT            TOP (100) PERCENT t1.lot_id, t1.lot_no, t1.job, CASE WHEN re.recorded_at IS NULL THEN 'MS' ELSE 'MF' END AS ステータス, format(t1.recorded_at, 'yyyy-MM-dd HH:mm:ss') AS 製造開始日時, CONVERT(varchar, 
                        ISNULL(format(re.recorded_at, 'yyyy-MM-dd HH:mm:ss'), '')) AS 製造終了日時, mc.name AS 装置名
FROM              (SELECT            l.id AS lot_id, RTRIM(l.lot_no) AS lot_no, RTRIM(p.name) AS package, RTRIM(d.name) AS device, r.record_class, r.job_id, j.name AS job, r.recorded_at, r.machine_id
                         FROM              APCSProDB.trans.lots AS l WITH (NOLOCK) INNER JOIN
                                                 APCSProDB.trans.lot_process_records AS r WITH (NOLOCK) ON r.lot_id = l.id AND r.record_class IN (1) INNER JOIN
                                                 APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.id = l.act_device_name_id AND d.is_assy_only IN (0, 1) INNER JOIN
                                                 APCSProDB.method.packages AS p WITH (NOLOCK) ON p.id = l.act_package_id INNER JOIN
                                                 APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = r.job_id
                         WHERE             (j.name LIKE 'AUTO(%') AND (l.act_package_id IN (242)) AND (r.recorded_at > DATEADD(day, - 1, GETDATE()))) AS t1 LEFT OUTER JOIN
                        APCSProDB.trans.lot_process_records AS re WITH (NOLOCK) ON re.lot_id = t1.lot_id AND re.recorded_at > t1.recorded_at AND re.record_class IN (2) AND re.job_id = t1.job_id AND NOT EXISTS
                            (SELECT            id, day_id, recorded_at, operated_by, record_class, lot_id, process_id, job_id, step_no, qty_in, qty_pass, qty_fail, qty_last_pass, qty_last_fail, qty_pass_step_sum, qty_fail_step_sum, qty_divided, qty_hasuu, qty_out, 
                                                       recipe, recipe_version, machine_id, position_id, process_job_id, is_onlined, dbx_id, wip_state, process_state, quality_state, first_ins_state, final_ins_state, is_special_flow, special_flow_id, is_temp_devided, 
                                                       temp_devided_count, container_no, extend_data, std_time_sum, pass_plan_time, pass_plan_time_up, origin_material_id, treatment_time, wait_time, qc_comment_id, qc_memo_id, created_at, created_by, updated_at, 
                                                       updated_by, act_device_name_id, device_slip_id, order_id, abc_judgement, held_at, held_minutes_current, limit_time_state, map_edit_state
                               FROM              APCSProDB.trans.lot_process_records AS r2 WITH (NOLOCK)
                               WHERE             (record_class = re.record_class) AND (lot_id = re.lot_id) AND (job_id = re.job_id) AND (recorded_at > t1.recorded_at) AND (recorded_at < re.recorded_at)) LEFT OUTER JOIN
                        APCSProDB.mc.machines AS mc WITH (NOLOCK) ON mc.id = t1.machine_id
ORDER BY       t1.recorded_at, t1.lot_no

GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "re"
            Begin Extent = 
               Top = 6
               Left = 237
               Bottom = 136
               Right = 453
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "mc"
            Begin Extent = 
               Top = 6
               Left = 491
               Bottom = 136
               Right = 701
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 199
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 7425
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_scheduler_operation_record_base_v03';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_scheduler_operation_record_base_v03';

