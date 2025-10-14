CREATE VIEW dbo.view_front_flow_check_base_v01
AS
SELECT            RTRIM(p.name) AS package_name, p.short_name AS form_name, p.is_enabled AS package_enabled, RTRIM(d.name) AS device_name, d.id AS device_name_id, d.assy_name, d.rank, d.tp_rank, d.is_assy_only, s.device_slip_id, 
                        s.version_num, s.tp_code, s.os_program_name, s.sub_rank, s.temporary_char, s.is_released, s.created_at, s.created_by, s.updated_at, s.updated_by, MAX(CASE WHEN fp.assy_ft_class = 'A' THEN fp.link_flow_no ELSE NULL END) 
                        AS Pro_flow_no_A, MAX(CASE WHEN fp.assy_ft_class = 'A' THEN fp.version_num ELSE NULL END) AS Pro_flow_version_A, MAX(CASE WHEN fp.assy_ft_class = 'F' THEN fp.link_flow_no ELSE NULL END) AS Pro_flow_no_F, 
                        MAX(CASE WHEN fp.assy_ft_class = 'F' THEN fp.version_num ELSE NULL END) AS Pro_flow_version_F, MAX(CASE WHEN fp.assy_ft_class = 'P' THEN fp.link_flow_no ELSE NULL END) AS Pro_flow_no_P, 
                        MAX(CASE WHEN fp.assy_ft_class = 'P' THEN fp.version_num ELSE NULL END) AS Pro_flow_version_P, MAX(CASE WHEN fp2.assy_ft_class = 'A' THEN fp2.version_num ELSE NULL END) AS Pro_flow_latest_A, 
                        MAX(CASE WHEN fp2.assy_ft_class = 'F' THEN fp2.version_num ELSE NULL END) AS Pro_flow_latest_F, MAX(CASE WHEN fp2.assy_ft_class = 'P' THEN fp2.version_num ELSE NULL END) AS Pro_flow_latest_P,
                            (SELECT            COUNT(*) AS Expr1
                               FROM              APCSProDB.trans.lots AS l WITH (nolock)
                               WHERE             (act_device_name_id = d.id)) AS all_lot_count,
                            (SELECT            COUNT(*) AS Expr1
                               FROM              APCSProDB.trans.lots AS l WITH (nolock)
                               WHERE             (act_device_name_id = d.id) AND (wip_state <= 20)) AS wip_lot_count,
                            (SELECT            COUNT(*) AS Expr1
                               FROM              APCSProDB.trans.lots AS l WITH (nolock)
                               WHERE             (device_slip_id = s.device_slip_id)) AS all_lot_count_currentslip,
                            (SELECT            COUNT(*) AS Expr1
                               FROM              APCSProDB.trans.lots AS l WITH (nolock)
                               WHERE             (device_slip_id = s.device_slip_id) AND (wip_state <= 20)) AS wip_lot_count_currentslip, s.tp_code AS Expr1, s.os_program_name AS Expr2, s.sub_rank AS Expr3, s.temporary_char AS Expr4, s.comments
FROM              APCSProDB.method.packages AS p WITH (nolock) INNER JOIN
                        APCSProDB.method.device_names AS d WITH (nolock) ON d.package_id = p.id LEFT OUTER JOIN
                        APCSProDB.method.device_versions AS v WITH (nolock) ON v.device_name_id = d.id AND v.device_type IN (0, 1) LEFT OUTER JOIN
                        APCSProDB.method.device_slips AS s WITH (nolock) ON s.device_id = v.device_id AND s.is_released IN (1, 2) AND NOT EXISTS
                            (SELECT            device_slip_id, device_id, version_num, package_slip_id, tp_code, os_program_name, sub_rank, temporary_char, comments, is_released, normal_leadtime_minutes, lead_time_sum, created_at, created_by, 
                                                       updated_at, updated_by
                               FROM              APCSProDB.method.device_slips AS s2 WITH (nolock)
                               WHERE             (device_id = s.device_id) AND (is_released IN (1, 2)) AND (version_num > s.version_num)) LEFT OUTER JOIN
                        APCSProDB.method.device_flow_patterns AS dfp WITH (nolock) ON dfp.device_slip_id = s.device_slip_id LEFT OUTER JOIN
                        APCSProDB.method.flow_patterns AS fp WITH (nolock) ON fp.id = dfp.flow_pattern_id LEFT OUTER JOIN
                        APCSProDB.method.flow_patterns AS fp2 WITH (nolock) ON fp2.assy_ft_class = fp.assy_ft_class AND fp2.link_flow_no = fp.link_flow_no AND fp2.version_num > fp.version_num AND fp2.is_released IN (1)
GROUP BY      p.name, p.short_name, p.is_enabled, d.name, d.assy_name, d.rank, d.tp_rank, d.id, d.is_assy_only, s.device_slip_id, s.version_num, s.is_released, s.created_at, s.created_by, s.updated_at, s.updated_by, s.tp_code, 
                        s.os_program_name, s.sub_rank, s.temporary_char, s.comments

GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[39] 2[2] 3) )"
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
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 264
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 302
               Bottom = 114
               Right = 513
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v"
            Begin Extent = 
               Top = 6
               Left = 551
               Bottom = 114
               Right = 771
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 809
               Bottom = 114
               Right = 1137
            End
            DisplayFlags = 280
            TopColumn = 7
         End
         Begin Table = "dfp"
            Begin Extent = 
               Top = 114
               Left = 38
               Bottom = 222
               Right = 210
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "fp"
            Begin Extent = 
               Top = 114
               Left = 248
               Bottom = 222
               Right = 429
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "fp2"
            Begin Extent = 
               Top = 114
               Left = 467
               Bottom = 222
               Right = 648
            End
            DisplayFlags = 280
            TopColumn = 0
         End', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_front_flow_check_base_v01';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 39
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
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
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_front_flow_check_base_v01';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_front_flow_check_base_v01';

