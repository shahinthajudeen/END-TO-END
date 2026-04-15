@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Student View'
define root view entity ZI_END_055_STUDENT
  as select from zdb_end_055
{
  key student_id as StudentID,
  first_name     as FirstName,
  last_name      as LastName,
  age            as Age,
  course_grade   as CourseGrade,
  last_changed_at as LastChangedAt
}
