" ====================================================================
" 1. MEMORY BUFFERS (ABAP Cloud Strict Mode Compliant)
" ====================================================================
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA: mt_create TYPE TABLE OF zdb_end_055,
                mt_update TYPE TABLE OF zdb_end_055,
                mt_delete TYPE TABLE OF zdb_end_055.
ENDCLASS.

" ====================================================================
" 2. HANDLER CLASS (Interaction Phase - NO DB UPDATES ALLOWED HERE)
" ====================================================================
CLASS lhc_Student DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Student RESULT result.

    " Renamed methods to avoid ABAP keyword clashes
    METHODS create_student FOR MODIFY
      IMPORTING entities FOR CREATE Student.

    METHODS update_student FOR MODIFY
      IMPORTING entities FOR UPDATE Student.

    METHODS delete_student FOR MODIFY
      IMPORTING keys FOR DELETE Student.

    METHODS read_student FOR READ
      IMPORTING keys FOR READ Student RESULT result.

    METHODS lock_student FOR LOCK
      IMPORTING keys FOR LOCK Student.
ENDCLASS.

CLASS lhc_Student IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create_student.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      " 1. Map data to the database structure
      DATA(ls_new_student) = VALUE zdb_end_055(
        student_id   = |S{ sy-uzeit }| " Simple ID generation
        first_name   = <entity>-FirstName
        last_name    = <entity>-LastName
        age          = <entity>-Age
        course_grade = <entity>-CourseGrade
      ).

      " 2. Append to buffer
      APPEND ls_new_student TO lcl_buffer=>mt_create.

      " 3. Map the temporary UI ID (%cid) to the real ID
      INSERT VALUE #( %cid      = <entity>-%cid
                      StudentID = ls_new_student-student_id )
             INTO TABLE mapped-student.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_student.
    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    " 1. Fetch existing database records
    SELECT * FROM zdb_end_055
      FOR ALL ENTRIES IN @entities
      WHERE student_id = @entities-StudentID
      INTO TABLE @DATA(lt_existing).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      " 2. Read the old data for this specific student
      READ TABLE lt_existing INTO DATA(ls_update)
           WITH KEY student_id = <entity>-StudentID.

      IF sy-subrc = 0.
        " 3. Apply %control logic (Update ONLY the fields the user edited)
        IF <entity>-%control-FirstName = if_abap_behv=>mk-on.
          ls_update-first_name = <entity>-FirstName.
        ENDIF.

        IF <entity>-%control-LastName = if_abap_behv=>mk-on.
          ls_update-last_name = <entity>-LastName.
        ENDIF.

        IF <entity>-%control-Age = if_abap_behv=>mk-on.
          ls_update-age = <entity>-Age.
        ENDIF.

        IF <entity>-%control-CourseGrade = if_abap_behv=>mk-on.
          ls_update-course_grade = <entity>-CourseGrade.
        ENDIF.

        " 4. Append merged record to update buffer
        APPEND ls_update TO lcl_buffer=>mt_update.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_student.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      " Append to delete buffer
      APPEND VALUE #( student_id = <key>-StudentID ) TO lcl_buffer=>mt_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_student.
    " Prevent crashing if keys table is empty
    IF keys IS NOT INITIAL.
      SELECT * FROM zdb_end_055
        FOR ALL ENTRIES IN @keys
        WHERE student_id = @keys-StudentID
        INTO TABLE @DATA(lt_students).

      " Map all fields so the Fiori UI shows the data
      result = CORRESPONDING #( lt_students MAPPING StudentID   = student_id
                                                    FirstName   = first_name
                                                    LastName    = last_name
                                                    Age         = age
                                                    CourseGrade = course_grade ).
    ENDIF.
  ENDMETHOD.

  METHOD lock_student.
  ENDMETHOD.
ENDCLASS.

" ====================================================================
" 3. SAVER CLASS (Save Phase - DB UPDATES HAPPEN HERE)
" ====================================================================
CLASS lsc_Student DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_Student IMPLEMENTATION.
  METHOD save.
    " Now we execute the actual database changes
    IF lcl_buffer=>mt_create IS NOT INITIAL.
      INSERT zdb_end_055 FROM TABLE @lcl_buffer=>mt_create.
    ENDIF.

    IF lcl_buffer=>mt_update IS NOT INITIAL.
      UPDATE zdb_end_055 FROM TABLE @lcl_buffer=>mt_update.
    ENDIF.

    IF lcl_buffer=>mt_delete IS NOT INITIAL.
      DELETE zdb_end_055 FROM TABLE @lcl_buffer=>mt_delete.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    " Clear buffers after saving or if the transaction is cancelled
    CLEAR: lcl_buffer=>mt_create, lcl_buffer=>mt_update, lcl_buffer=>mt_delete.
  ENDMETHOD.
ENDCLASS.
