@EndUserText.label: 'Student Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_END_055_STUDENT
  provider contract transactional_query
  as projection on ZI_END_055_STUDENT
{
  key StudentID,
  FirstName,
  LastName,
  Age,
  CourseGrade,
  LastChangedAt
}
