*&---------------------------------------------------------------------*
*&  Include           ZHR_CARGA_EXCEL_SCR
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.

PARAMETERS p_file TYPE rlgrap-filename OBLIGATORY.
PARAMETERS p_test TYPE c AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b1.
