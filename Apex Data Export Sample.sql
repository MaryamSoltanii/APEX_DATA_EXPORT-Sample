DECLARE
  L_AGGREGATES   APEX_DATA_EXPORT.T_AGGREGATES;
  L_COLUMNS      APEX_DATA_EXPORT.T_COLUMNS;
  L_PRINT_CONFIG APEX_DATA_EXPORT.T_PRINT_CONFIG;
  L_CONTEXT      APEX_EXEC.T_CONTEXT;
  L_EXPORT       APEX_DATA_EXPORT.T_EXPORT;
  L_HIGHLIGHTS   APEX_DATA_EXPORT.T_HIGHLIGHTS;
BEGIN
  APEX_DATA_EXPORT.ADD_HIGHLIGHT(P_HIGHLIGHTS       => L_HIGHLIGHTS,
                                 P_ID               => 1,
                                 P_VALUE_COLUMN     => 'HIGHLIGHT1',
                                 P_DISPLAY_COLUMN   => '',
                                 P_TEXT_COLOR       => '#ffffff',
                                 P_BACKGROUND_COLOR => '#5f7d4f');
  APEX_DATA_EXPORT.ADD_AGGREGATE(P_AGGREGATES           => L_AGGREGATES,
                                 P_LABEL                => 'Sum',
                                 P_FORMAT_MASK          => 'FML999G999G999G999G990D00',
                                 P_DISPLAY_COLUMN       => 'SAL',
                                 P_VALUE_COLUMN         => 'AGGREGATE1',
                                 P_OVERALL_LABEL        => 'Total sum',
                                 P_OVERALL_VALUE_COLUMN => 'OVERALL1');
  ---------------aggregate
  APEX_DATA_EXPORT.ADD_COLUMN(P_COLUMNS         => L_COLUMNS,
                              P_NAME            => 'DEPTNO',
                              P_IS_COLUMN_BREAK => TRUE);
  APEX_DATA_EXPORT.ADD_COLUMN(P_COLUMNS => L_COLUMNS, P_NAME => 'EMPNO');
  APEX_DATA_EXPORT.ADD_COLUMN(P_COLUMNS => L_COLUMNS, P_NAME => 'ENAME');
  APEX_DATA_EXPORT.ADD_COLUMN(P_COLUMNS => L_COLUMNS, P_NAME => 'SAL');
  L_CONTEXT := APEX_EXEC.OPEN_QUERY_CONTEXT(P_LOCATION  => APEX_EXEC.C_LOCATION_LOCAL_DB,
                                            P_SQL_QUERY => '
                                            SELECT DEPTNO,
                                                   EMPNO,
                                                   ENAME,
                                                   SAL,
                                                   CASE
                                                     WHEN SAL >= 3000 THEN
                                                      1
                                                   END AS HIGHLIGHT1,
                                                   SUM(SAL) OVER(PARTITION BY DEPTNO) AS AGGREGATE1,
                                                   SUM(SAL) OVER() AS OVERALL1
                                              FROM EBA_DEMO_APPR_EMP
                                            ');

  L_PRINT_CONFIG := APEX_DATA_EXPORT.GET_PRINT_CONFIG(P_ORIENTATION             => APEX_DATA_EXPORT.C_ORIENTATION_PORTRAIT,
                                                      P_PAGE_HEADER             => 'EBA_DEMO_APPR_EMP',
                                                      P_PAGE_HEADER_FONT_COLOR  => '#5f7d4f',
                                                      P_PAGE_HEADER_FONT_WEIGHT => APEX_DATA_EXPORT.C_FONT_WEIGHT_BOLD,
                                                      P_PAGE_HEADER_FONT_SIZE   => 14,
                                                      P_BORDER_WIDTH            => 2);
  /*formats
  c_format_csv   =>'CSV';
  c_format_html  =>'HTML';
  c_format_pdf   =>'PDF';
  c_format_xlsx  =>'XLSX';
  c_format_xml   =>'XML';
  c_format_pxml  =>'PXML';
  c_format_json  =>'JSON';
  c_format_pjson => 'PJSON'
  */
  L_EXPORT := APEX_DATA_EXPORT.EXPORT(P_CONTEXT      => L_CONTEXT,
                                      P_PRINT_CONFIG => L_PRINT_CONFIG,
                                      P_FORMAT       => APEX_DATA_EXPORT.C_FORMAT_PDF,
                                      P_HIGHLIGHTS   => L_HIGHLIGHTS,
                                      P_COLUMNS      => L_COLUMNS,
                                      P_AGGREGATES   => L_AGGREGATES);

  APEX_EXEC.CLOSE(L_CONTEXT);

  INSERT INTO TB_ATTACHMENT
    (FILE_NAME, MIME_TYPE, ROW_COUNT, CONTENT_BLOB)
  VALUES
    (L_EXPORT.FILE_NAME,
     L_EXPORT.MIME_TYPE,
     L_EXPORT.ROW_COUNT,
     L_EXPORT.CONTENT_BLOB);
  COMMIT;
  APEX_DATA_EXPORT.DOWNLOAD(P_EXPORT              => L_EXPORT,
                            P_STOP_APEX_ENGINE    => TRUE);

EXCEPTION
  WHEN OTHERS THEN
    APEX_EXEC.CLOSE(L_CONTEXT);
    RAISE;
END;
