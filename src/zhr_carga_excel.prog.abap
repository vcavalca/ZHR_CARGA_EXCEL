*----------------------------------------------------------------------*
* Autor......:                                                         *
* Descrição  : Load Program for table T7BREFD_EVENT                    *
* Projeto....: eSocial                                                 *
* Data.......:                                                         *
*&---------------------------------------------------------------------*
*& Report ZHR_CARGA_EXCEL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zhr_carga_excel.

INCLUDE:  zhr_carga_excel_top,
          zhr_carga_excel_scr,
          zhr_carga_excel_f01.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM f_select_file USING p_file
                        CHANGING p_file.

START-OF-SELECTION.

  PERFORM f_check_file.

END-OF-SELECTION.
