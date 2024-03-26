*&---------------------------------------------------------------------*
*&  Include           ZHR_CARGA_EXCEL_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  F_SELECT_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_FILE  text
*      <--P_P_FILE  text
*----------------------------------------------------------------------*
FORM f_select_file USING p_in_file
                        CHANGING p_out_file.

* New way to display search help in the file path field
  DATA lv_return TYPE i.
  DATA lv_user_action TYPE i.

  CLEAR gt_filetable.

  TRY.
      cl_gui_frontend_services=>file_open_dialog(
          EXPORTING
              file_filter    = |xlsx (*.xlsx)\|*.xlsx\|{ cl_gui_frontend_services=>filetype_all }|
              multiselection = abap_true
          CHANGING
              file_table  = gt_filetable
              rc          = lv_return
              user_action = lv_user_action
      ).

      IF lv_user_action EQ cl_gui_frontend_services=>action_ok.
        IF lines( gt_filetable ) > 0.
          LOOP AT gt_filetable INTO DATA(lwa_file).
            CLEAR gwa_file_path.
            gwa_file_path-line = lwa_file-filename.
            APPEND gwa_file_path TO gt_file_path.
            p_out_file = lwa_file-filename.
          ENDLOOP.
        ENDIF.
      ENDIF.

    CATCH cx_root INTO DATA(e_error_message).
      MESSAGE e_error_message->get_text( ) TYPE 'I'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  F_OPEN_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_check_file.

  IF gt_check_file IS INITIAL. " Condition for assigning file path if you have not used search help.
    LOOP AT gt_file_path INTO DATA(lwa_file_path).
      gwa_check_file-line = lwa_file_path-line.
      APPEND gwa_check_file TO gt_check_file.
    ENDLOOP.

    IF gt_check_file IS INITIAL.
      gwa_check_file-line = p_file.
      APPEND gwa_check_file TO gt_check_file.
    ENDIF.
  ENDIF.

  LOOP AT gt_check_file INTO DATA(lwa_hold_file).
    SEARCH lwa_hold_file-line FOR '.xlsx' AND MARK.
    IF sy-subrc IS INITIAL.
      gv_xlsx = abap_true. "If you find .xlsx, save it in a bool variable
    ELSE.
      gv_xlsx = abap_false.
    ENDIF.
  ENDLOOP.

  IF gv_xlsx EQ abap_true. "Condition to check if file has the extension .xlsx
    LOOP AT gt_check_file INTO DATA(lwa_pass_to).
      PERFORM f_read_file USING lwa_pass_to-line. "If so, it performs the next step, which is to read the file.
    ENDLOOP.
  ELSE.
    MESSAGE 'This program only accepts .xlsx files, please dont insist!' TYPE 'I'. "If not, inform that it does not accept any other type of file.
  ENDIF.

  IF gt_t7brefd_event IS NOT INITIAL.
    "IF p_test EQ abap_true.
    "PERFORM f_print_alv.
    "ELSE.
    PERFORM f_insert_table.
    PERFORM f_print_alv.
    "PERFORM f_print_alv.
    "ENDIF.
  ELSE.
    MESSAGE 'There is no data to load' TYPE 'I'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  F_READ_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_read_file USING lwa_pass_to-line.

  DATA: lv_filesize TYPE w3param-cont_len,
        lv_filetype TYPE w3param-cont_type,
        it_bin_data TYPE w3mimetabtype.

  cl_gui_frontend_services=>gui_upload( EXPORTING
                                          filename = lwa_pass_to-line
                                          filetype = 'BIN'
                                          IMPORTING
                                            filelength = lv_filesize
                                            CHANGING
                                              data_tab = it_bin_data ).

  DATA(lv_bin_data) = cl_bcs_convert=>solix_to_xstring( it_solix = it_bin_data ).

  DATA(o_excel) = NEW cl_fdt_xl_spreadsheet( document_name = CONV #( lwa_pass_to-line )
                                              xdocument = lv_bin_data ).

  DATA: it_worksheet_names TYPE if_fdt_doc_spreadsheet=>t_worksheet_names.

  o_excel->if_fdt_doc_spreadsheet~get_worksheet_names( IMPORTING worksheet_names = it_worksheet_names ).

  IF lines( it_worksheet_names ) > 0.

    DATA(o_worksheet_itab) = o_excel->if_fdt_doc_spreadsheet~get_itab_from_worksheet( it_worksheet_names[ 1 ] ).

    FIELD-SYMBOLS: <worksheet> TYPE ANY TABLE.
    ASSIGN o_worksheet_itab->* TO <worksheet>.

    DATA: o_row TYPE REF TO data.
    CREATE DATA o_row LIKE LINE OF <worksheet>.
    ASSIGN o_row->* TO FIELD-SYMBOL(<row>).

    FIELD-SYMBOLS: <fs_mandt>            TYPE string,
                   <fs_event_id>         TYPE string,
                   <fs_event_type>       TYPE string,
                   <fs_status>           TYPE string,
                   <fs_inf_type>         TYPE string,
                   <fs_inf_value>        TYPE string,
                   <fs_begda>            TYPE string,
                   <fs_endda>            TYPE string,
                   <fs_event_receipt>    TYPE string,
                   <fs_retif_receipt>    TYPE string,
                   <fs_adjustment_ind>   TYPE string,
                   <fs_environment_type> TYPE string,
                   <fs_send_process>     TYPE string,
                   <fs_segment_ind>      TYPE string,
                   <fs_version_process>  TYPE string,
                   <fs_operation_ind>    TYPE string,
                   <fs_event_rectified>  TYPE string,
                   <fs_search_criteria>  TYPE string,
                   <fs_event_validity>   TYPE string,
                   <fs_version>          TYPE string,
                   <fs_bukrs>            TYPE string,
                   <fs_werks>            TYPE string,
                   <fs_btrtl>            TYPE string,
                   <fs_gen_class>        TYPE string,
                   <fs_migration_date>   TYPE string,
                   <fs_selection_begda>  TYPE string,
                   <fs_selection_endda>  TYPE string,
                   <fs_guia_ind>         TYPE string.

    DATA: lv_begda           TYPE datum,
          lv_endda           TYPE datum,
          lv_event_validity  TYPE datum,
          lv_selection_begda TYPE datum,
          lv_selection_endda TYPE datum.

    LOOP AT <worksheet> ASSIGNING <row>.

      IF sy-tabix > 1.
        ASSIGN COMPONENT 1 OF STRUCTURE <row> TO <fs_mandt>.
        ASSIGN COMPONENT 2 OF STRUCTURE <row> TO <fs_event_id>.
        ASSIGN COMPONENT 3 OF STRUCTURE <row> TO <fs_event_type>.
        ASSIGN COMPONENT 4 OF STRUCTURE <row> TO <fs_status>.
        ASSIGN COMPONENT 5 OF STRUCTURE <row> TO <fs_inf_type>.
        ASSIGN COMPONENT 6 OF STRUCTURE <row> TO <fs_inf_value>.
        ASSIGN COMPONENT 7 OF STRUCTURE <row> TO <fs_begda>.
        ASSIGN COMPONENT 8 OF STRUCTURE <row> TO <fs_endda>.
        ASSIGN COMPONENT 9 OF STRUCTURE <row> TO <fs_event_receipt>.
        ASSIGN COMPONENT 10 OF STRUCTURE <row> TO <fs_retif_receipt>.
        ASSIGN COMPONENT 11 OF STRUCTURE <row> TO <fs_adjustment_ind>.
        ASSIGN COMPONENT 12 OF STRUCTURE <row> TO <fs_environment_type>.
        ASSIGN COMPONENT 13 OF STRUCTURE <row> TO <fs_send_process>.
        ASSIGN COMPONENT 14 OF STRUCTURE <row> TO <fs_segment_ind>.
        ASSIGN COMPONENT 15 OF STRUCTURE <row> TO <fs_version_process>.
        ASSIGN COMPONENT 16 OF STRUCTURE <row> TO <fs_operation_ind>.
        ASSIGN COMPONENT 17 OF STRUCTURE <row> TO <fs_event_rectified>.
        ASSIGN COMPONENT 18 OF STRUCTURE <row> TO <fs_search_criteria>.
        ASSIGN COMPONENT 19 OF STRUCTURE <row> TO <fs_event_validity>.
        ASSIGN COMPONENT 20 OF STRUCTURE <row> TO <fs_version>.
        ASSIGN COMPONENT 21 OF STRUCTURE <row> TO <fs_bukrs>.
        ASSIGN COMPONENT 22 OF STRUCTURE <row> TO <fs_werks>.
        ASSIGN COMPONENT 23 OF STRUCTURE <row> TO <fs_btrtl>.
        ASSIGN COMPONENT 24 OF STRUCTURE <row> TO <fs_gen_class>.
        ASSIGN COMPONENT 25 OF STRUCTURE <row> TO <fs_migration_date>.
        ASSIGN COMPONENT 26 OF STRUCTURE <row> TO <fs_selection_begda>.
        ASSIGN COMPONENT 27 OF STRUCTURE <row> TO <fs_selection_endda>.
        ASSIGN COMPONENT 28 OF STRUCTURE <row> TO <fs_guia_ind>.

        CLEAR: lv_begda,
                lv_endda,
                lv_event_validity,
                lv_selection_begda,
                lv_selection_endda.

        PERFORM:  date_convert USING <fs_begda> CHANGING lv_begda,
                  date_convert USING <fs_endda> CHANGING lv_endda,
                  date_convert USING <fs_event_validity> CHANGING lv_event_validity,
                  date_convert USING <fs_selection_begda> CHANGING lv_selection_begda,
                  date_convert USING <fs_selection_endda> CHANGING lv_selection_endda.

        CLEAR gwa_t7brefd_event.

        gwa_t7brefd_event-mandt = <fs_mandt>.
        gwa_t7brefd_event-event_id = <fs_event_id>.
        gwa_t7brefd_event-event_type = <fs_event_type>.
        gwa_t7brefd_event-status = <fs_status>.
        gwa_t7brefd_event-inf_type = <fs_inf_type>.
        gwa_t7brefd_event-inf_value = <fs_inf_value>.
        gwa_t7brefd_event-begda = lv_begda.
        gwa_t7brefd_event-endda = lv_endda.
        gwa_t7brefd_event-event_receipt = <fs_event_receipt>.
        gwa_t7brefd_event-retif_receipt = <fs_retif_receipt>.
        gwa_t7brefd_event-adjustment_ind = <fs_adjustment_ind>.
        gwa_t7brefd_event-environment_type = <fs_environment_type>.
        gwa_t7brefd_event-send_process = <fs_send_process>.
        gwa_t7brefd_event-segment_ind = <fs_segment_ind>.
        gwa_t7brefd_event-version_process = <fs_version_process>.
        gwa_t7brefd_event-operation_ind = <fs_operation_ind>.
        gwa_t7brefd_event-event_rectified = <fs_event_rectified>.
        gwa_t7brefd_event-search_criteria = <fs_search_criteria>.
        gwa_t7brefd_event-event_validity = lv_event_validity.
        gwa_t7brefd_event-version = <fs_version>.
        gwa_t7brefd_event-bukrs = <fs_bukrs>.
        gwa_t7brefd_event-werks = <fs_werks>.
        gwa_t7brefd_event-btrtl = <fs_btrtl>.
        gwa_t7brefd_event-gen_class = <fs_gen_class>.
        IF <fs_migration_date> IS INITIAL.
          gwa_t7brefd_event-migration_date = sy-datum.
        ELSE.
          gwa_t7brefd_event-migration_date = <fs_migration_date>.
        ENDIF.
        gwa_t7brefd_event-selection_begda = lv_selection_begda.
        gwa_t7brefd_event-selection_endda = lv_selection_endda.
        gwa_t7brefd_event-guia_ind = <fs_guia_ind>.

        APPEND gwa_t7brefd_event TO gt_t7brefd_event.

      ENDIF.

    ENDLOOP.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  F_INSERT_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_insert_table.

  DATA: lt_t7brefd_event  TYPE TABLE OF t7brefd_event,
        lwa_t7brefd_event TYPE t7brefd_event,
        lwa_on_hold       TYPE t7brefd_event,
        lt_hold_select    TYPE TABLE OF t7brefd_event,
        lwa_hold_select   TYPE t7brefd_event.

  CLEAR lt_hold_select.
  SELECT *
    INTO TABLE @lt_hold_select
    FROM t7brefd_event.

  IF  sy-subrc IS INITIAL.


    LOOP AT gt_t7brefd_event INTO lwa_on_hold.

      READ TABLE lt_hold_select WITH KEY inf_type = lwa_on_hold-inf_type
                                         inf_value = lwa_on_hold-inf_value
                                         begda = lwa_on_hold-begda
                                         endda = lwa_on_hold-endda
                                     TRANSPORTING NO FIELDS.

      IF sy-subrc IS INITIAL.

        IF p_test EQ abap_true.

          MOVE-CORRESPONDING lwa_on_hold TO gwa_alv_print.
          CLEAR: lwa_on_hold-status,
                 lwa_on_hold-event_receipt.
          lwa_on_hold-status = 3. "Change status by 3
          lwa_on_hold-event_receipt = lwa_on_hold-event_receipt.
          gwa_alv_print-icone = '@5D@'.
          gwa_alv_print-out_msg = 'Test mode'.
          APPEND gwa_alv_print TO gt_alv_print.

        ELSE.

          MOVE-CORRESPONDING lwa_on_hold TO lwa_hold_select.
          CLEAR: lwa_hold_select-status,
                 lwa_hold_select-event_receipt.
          lwa_hold_select-status = 3. "Change status by 3
          lwa_hold_select-event_receipt = lwa_on_hold-event_receipt. "Change the event_receipt to the data in excel

          MODIFY t7brefd_event FROM lwa_hold_select.
          COMMIT WORK.


          IF sy-subrc IS INITIAL.


            MOVE-CORRESPONDING lwa_hold_select TO gwa_alv_print.
            gwa_alv_print-icone = '@5B@'.
            gwa_alv_print-out_msg = 'Modified'.
            APPEND gwa_alv_print TO gt_alv_print.

          ELSEIF  sy-subrc IS NOT INITIAL.

            MOVE-CORRESPONDING lwa_hold_select TO gwa_alv_print.
            gwa_alv_print-icone = '@5C@'.
            gwa_alv_print-out_msg = 'Error modifying file'.
            APPEND gwa_alv_print TO gt_alv_print.

          ENDIF.

        ENDIF.

      ELSE.

        IF p_test EQ abap_true.

          MOVE-CORRESPONDING lwa_on_hold TO gwa_alv_print.
          gwa_alv_print-icone = '@5D@'.
          gwa_alv_print-out_msg = 'Test mode'.
          APPEND gwa_alv_print TO gt_alv_print.

        ELSE.
*
*          CLEAR lwa_t7brefd_event.
*          lwa_t7brefd_event = lwa_on_hold.
*         INSERT INTO zcarga_event VALUES lwa_t7brefd_event.
*
*          IF sy-subrc IS INITIAL.
*
          MOVE-CORRESPONDING lwa_on_hold TO gwa_alv_print.
          gwa_alv_print-icone = '@5D@'.
          gwa_alv_print-out_msg = 'Information not present in the table'.
          APPEND gwa_alv_print TO gt_alv_print.
*
*          ELSEIF  sy-subrc IS NOT INITIAL.
*
*            MOVE-CORRESPONDING lwa_t7brefd_event TO gwa_alv_print.
*            gwa_alv_print-icone = '@5C@'.
*            gwa_alv_print-out_msg = 'Erro ao inserir o arquivo'.
*            APPEND gwa_alv_print TO gt_alv_print.
*
*
*          ENDIF.

        ENDIF.

      ENDIF.

    ENDLOOP.

  ELSE.

    MESSAGE 'Does not contain data in the table' TYPE 'I'.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      FORM  F_PRINT_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_print_alv .

  PERFORM f_header.
  PERFORM f_set_layout.
  PERFORM set_field.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      is_layout              = ty_layout           "Structure with layout details.
      i_callback_top_of_page = 'F_TOP_PAGE'        "Structure to mount the header
      i_callback_program     = sy-repid            "system variable (program name). 'Sy-repid' = 'zcurso_alv1'
*     I_CALLBACK_USER_COMMAND = 'F_USER_COMMAND'   "Calls the "HOTSPOT" function
      i_save                 = 'A'                 "Layouts can be saved (buttons for changing the layout appear).
*     it_sort                = t_sort[]            "Performs the break with the given parameter.
      it_fieldcat            = ty_fieldcat_col     "table with the columns to be printed.
    TABLES
      t_outtab               = gt_alv_print.          "Table with the data to be printed.

ENDFORM.

*&---------------------------------------------------------------------*
*&      FORM  F_HEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_header .

  DATA: vl_data(10),
        vl_hora(10).

  CLEAR ty_watop.
  ty_watop-typ  = 'H'.    "H = Large, prominent | S = Small | A = Average with italics
  ty_watop-info = text-m01.

  APPEND ty_watop TO ty_top.

  CLEAR ty_watop.

  ty_watop-typ  = 'S'.
  CONCATENATE text-m02 sy-uname
    INTO ty_watop-info
      SEPARATED BY space.

  APPEND ty_watop TO ty_top.

  CLEAR ty_watop.

  ty_watop-typ  = 'S'.

  WRITE sy-datum TO vl_data USING EDIT MASK '__/__/____'.
  WRITE sy-uzeit TO vl_hora USING EDIT MASK '__:__'.

  CONCATENATE text-m03 vl_data  vl_hora
    INTO ty_watop-info
      SEPARATED BY space.

  APPEND ty_watop TO ty_top.

ENDFORM.                    " f_header

*&**********************************************************************
*&      FORM  F_TOP_PAGE                                               *
*&**********************************************************************
*       Defines the header of the ALV
*----------------------------------------------------------------------*
FORM f_top_page.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = ty_top.
  "i_logo             = ''.

ENDFORM.                    "f_top_page

*&---------------------------------------------------------------------*
*&      FORM  F_SET_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_set_layout .
  ty_layout-zebra             = 'X'.                            "Zebra
  ty_layout-colwidth_optimize = 'X'.                            "Automatically optimize column widths
ENDFORM.                    " F_SET_LAYOUT

*&---------------------------------------------------------------------*
*&      FORM  F_SET_FIELD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_field .
  "CLEAR IT_HRP1000.

  PERFORM f_set_column USING  'MANDT'             'GT_ALV_PRINT' text-t01      ' '  ' '  '25'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'EVENT_ID'          'GT_ALV_PRINT' text-t02      ' '  ' '  '80'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'EVENT_TYPE'        'GT_ALV_PRINT' text-t03      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'STATUS'            'GT_ALV_PRINT' text-t04      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'INF_TYPE'          'GT_ALV_PRINT' text-t05      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'INF_VALUE'         'GT_ALV_PRINT' text-t06      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'BEGDA'             'GT_ALV_PRINT' text-t07      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'ENDDA'             'GT_ALV_PRINT' text-t08      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'EVENT_RECEIPT'     'GT_ALV_PRINT' text-t09      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'RETIF_RECEIPT'     'GT_ALV_PRINT' text-t10      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'ADJUSTMENT_IND'    'GT_ALV_PRINT' text-t11      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'ENVIRONMENT_TYPE'  'GT_ALV_PRINT' text-t12      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'SEND_PROCESS'      'GT_ALV_PRINT' text-t13      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'SEGMENT_IND'       'GT_ALV_PRINT' text-t14      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'VERSION_PROCESS'   'GT_ALV_PRINT' text-t15      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'OPERATION_IND'     'GT_ALV_PRINT' text-t16      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'EVENT_RECTIFIED'   'GT_ALV_PRINT' text-t17      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'SEARCH_CRITERIA'   'GT_ALV_PRINT' text-t18      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'EVENT_VALIDITY'    'GT_ALV_PRINT' text-t19      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'VERSION'           'GT_ALV_PRINT' text-t20      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'BUKRS'             'GT_ALV_PRINT' text-t21      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'WERKS'             'GT_ALV_PRINT' text-t22      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'BTRTL'             'GT_ALV_PRINT' text-t23      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'GEN_CLASS'         'GT_ALV_PRINT' text-t24      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'MIGRATION_DATE'    'GT_ALV_PRINT' text-t25      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'SELECTION_BEGDA'   'GT_ALV_PRINT' text-t26      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'SELECTION_ENDDA'   'GT_ALV_PRINT' text-t27      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'GUIA_IND'          'GT_ALV_PRINT' text-t28      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'ICONE'             'GT_ALV_PRINT' text-t29      ' '  ' '  '20'  ' '  'L'  ' '.
  PERFORM f_set_column USING  'OUT_MSG'           'GT_ALV_PRINT' text-t30      ' '  ' '  '20'  ' '  'L'  ' '.

ENDFORM.                    "F_SET_FIELD

*&---------------------------------------------------------------------*
*&       FORM f_set_column                                             *
*----------------------------------------------------------------------*
*        Clears all tables and variables.
*----------------------------------------------------------------------*
FORM f_set_column USING p_fieldname
                        p_tabname
                        p_texto
                        p_ref_fieldname
                        p_ref_tabname
                        p_outputlen
                        p_emphasize
                        p_just
                        p_do_sum.

  ADD 1 TO vg_nrcol.
  ty_fieldcat-col_pos       = vg_nrcol.            "FIELD POSITION (COLUMN).
  ty_fieldcat-fieldname     = p_fieldname.         "INTERNAL TABLE FIELD.
  ty_fieldcat-tabname       = p_tabname.           "INTERNAL TABLE.
  ty_fieldcat-seltext_l     = p_texto.             "COLUMN NAME/TEXT.
  ty_fieldcat-ref_fieldname = p_ref_fieldname.     "REFERENCE FIELD.
  ty_fieldcat-ref_tabname   = p_ref_tabname.       "REFERENCE TABLE.
  ty_fieldcat-outputlen     = p_outputlen.         "COLUMN WIDTH.
  ty_fieldcat-emphasize     = p_emphasize.         "COLOR AN ENTIRE COLUMN.
  ty_fieldcat-just          = p_just.              "
  ty_fieldcat-do_sum        = p_do_sum.            "TOTALIZE.

  APPEND ty_fieldcat TO ty_fieldcat_col.           "Inserts row into internal table TY_FIELDCAT_COL.

ENDFORM.                    "f_set_column

*---------------------------------------------------------------------*
* Form DATE_CONVERT
*---------------------------------------------------------------------*
FORM date_convert USING iv_date_string TYPE string CHANGING cv_date TYPE datum .

  DATA: lv_convert_date(10) TYPE c.

  lv_convert_date = iv_date_string .

  "Check Date Format YYYY/MM/DD
  FIND REGEX '^\d{4}[/|-]\d{1,2}[/|-]\d{1,2}$' IN lv_convert_date.
  IF sy-subrc = 0.
    CALL FUNCTION '/SAPDMC/LSM_DATE_CONVERT'
      EXPORTING
        date_in             = lv_convert_date
        date_format_in      = 'DYMD'
        to_output_format    = ' '
        to_internal_format  = 'X'
      IMPORTING
        date_out            = lv_convert_date
      EXCEPTIONS
        illegal_date        = 1
        illegal_date_format = 2
        no_user_date_format = 3
        OTHERS              = 4.
  ELSE.

    " If not DD/MM/YYYY
    FIND REGEX '^\d{1,2}[/|-]\d{1,2}[/|-]\d{4}$' IN lv_convert_date.
    IF sy-subrc = 0.
      CALL FUNCTION '/SAPDMC/LSM_DATE_CONVERT'
        EXPORTING
          date_in             = lv_convert_date
          date_format_in      = 'DDMY'
          to_output_format    = ' '
          to_internal_format  = 'X'
        IMPORTING
          date_out            = lv_convert_date
        EXCEPTIONS
          illegal_date        = 1
          illegal_date_format = 2
          no_user_date_format = 3
          OTHERS              = 4.
    ENDIF.

  ENDIF.

  IF sy-subrc = 0.
    cv_date = lv_convert_date .
  ENDIF.

ENDFORM .
