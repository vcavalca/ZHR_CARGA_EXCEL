*&---------------------------------------------------------------------*
*&  Include           ZHR_CARGA_EXCEL_TOP
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*** Declaration of Tables
*&---------------------------------------------------------------------*
TABLES: t7brefd_event.
"zcarga_event.

*&---------------------------------------------------------------------*
*** Declaration of types
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_t7brefd_event,
         mandt            TYPE t7brefd_event-mandt,
         event_id         TYPE t7brefd_event-event_id,
         event_type       TYPE t7brefd_event-event_type,
         status           TYPE t7brefd_event-status,
         inf_type         TYPE t7brefd_event-inf_type,
         inf_value        TYPE t7brefd_event-inf_value,
         begda            TYPE t7brefd_event-begda,
         endda            TYPE t7brefd_event-endda,
         event_receipt    TYPE t7brefd_event-event_receipt,
         retif_receipt    TYPE t7brefd_event-retif_receipt,
         adjustment_ind   TYPE t7brefd_event-adjustment_ind,
         environment_type TYPE t7brefd_event-environment_type,
         send_process     TYPE t7brefd_event-send_process,
         segment_ind      TYPE t7brefd_event-segment_ind,
         version_process  TYPE t7brefd_event-version_process,
         operation_ind    TYPE t7brefd_event-operation_ind,
         event_rectified  TYPE t7brefd_event-event_rectified,
         search_criteria  TYPE t7brefd_event-search_criteria,
         event_validity   TYPE t7brefd_event-event_validity,
         version          TYPE t7brefd_event-version,
         bukrs            TYPE t7brefd_event-bukrs,
         werks            TYPE t7brefd_event-werks,
         btrtl            TYPE t7brefd_event-btrtl,
         gen_class        TYPE t7brefd_event-gen_class,
         migration_date   TYPE t7brefd_event-migration_date,
         selection_begda  TYPE t7brefd_event-begda,
         selection_endda  TYPE t7brefd_event-endda,
         guia_ind         TYPE t7brefd_event-guia_ind,
       END OF ty_t7brefd_event.

TYPES: BEGIN OF ty_alv_print,
         mandt            TYPE t7brefd_event-mandt,
         event_id         TYPE t7brefd_event-event_id,
         event_type       TYPE t7brefd_event-event_type,
         status           TYPE t7brefd_event-status,
         inf_type         TYPE t7brefd_event-inf_type,
         inf_value        TYPE t7brefd_event-inf_value,
         begda            TYPE t7brefd_event-begda,
         endda            TYPE t7brefd_event-endda,
         event_receipt    TYPE t7brefd_event-event_receipt,
         retif_receipt    TYPE t7brefd_event-retif_receipt,
         adjustment_ind   TYPE t7brefd_event-adjustment_ind,
         environment_type TYPE t7brefd_event-environment_type,
         send_process     TYPE t7brefd_event-send_process,
         segment_ind      TYPE t7brefd_event-segment_ind,
         version_process  TYPE t7brefd_event-version_process,
         operation_ind    TYPE t7brefd_event-operation_ind,
         event_rectified  TYPE t7brefd_event-event_rectified,
         search_criteria  TYPE t7brefd_event-search_criteria,
         event_validity   TYPE t7brefd_event-event_validity,
         version          TYPE t7brefd_event-version,
         bukrs            TYPE t7brefd_event-bukrs,
         werks            TYPE t7brefd_event-werks,
         btrtl            TYPE t7brefd_event-btrtl,
         gen_class        TYPE t7brefd_event-gen_class,
         migration_date   TYPE t7brefd_event-migration_date,
         selection_begda  TYPE t7brefd_event-begda,
         selection_endda  TYPE t7brefd_event-endda,
         guia_ind         TYPE t7brefd_event-guia_ind,
         icone(4),
         out_msg          TYPE string,
       END OF ty_alv_print.

TYPES: BEGIN OF ty_file_path,
         line TYPE string,
       END OF ty_file_path.

*&---------------------------------------------------------------------*
*** Declaration of global Internal Tables
*&---------------------------------------------------------------------*
DATA: gt_t7brefd_event TYPE TABLE OF ty_t7brefd_event,
      gt_file_path     TYPE TABLE OF ty_file_path,
      gt_alv_print     TYPE TABLE OF ty_alv_print,
      gt_filetable     TYPE filetable,
      gt_check_file    TYPE TABLE OF ty_file_path.

*&---------------------------------------------------------------------*
*** Declaration of global work areas
*&---------------------------------------------------------------------*
DATA: gwa_t7brefd_event TYPE ty_t7brefd_event,
      gwa_file_path     TYPE ty_file_path,
      gwa_alv_print     TYPE ty_alv_print,
      gwa_check_file    TYPE ty_file_path.

*&---------------------------------------------------------------------*
*** Declaration of Global Variables
*&---------------------------------------------------------------------*
DATA: gv_xlsx      TYPE abap_bool.

*&---------------------------------------------------------------------*
*&  Alv Structures                                                  *
*&---------------------------------------------------------------------*
DATA:  vg_nrcol(4) TYPE c.

DATA: ty_layout       TYPE slis_layout_alv,
      ty_top          TYPE slis_t_listheader,
      ty_watop        TYPE slis_listheader,
      ty_fieldcat_col TYPE slis_t_fieldcat_alv,
      ty_fieldcat     TYPE slis_fieldcat_alv,
      ty_events       TYPE slis_t_event.

DATA : sch_repid TYPE sy-repid,
       sch_dynnr TYPE sy-dynnr,
       sch_field TYPE dynpread-fieldname,
       sch_objec TYPE objec,
       sch_subrc TYPE sy-subrc,
       per_beg   TYPE sy-datum,
       per_end   TYPE sy-datum.

TABLES hrvpv6a.
