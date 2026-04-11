using System.Collections.Generic;
using System.Web.Mvc;

namespace StudentInformationSystem.Models
{
    public class CourseStudentManagementViewModel
    {
        public int SelectedCourseId { get; set; }

        public Courses SelectedCourse { get; set; }

        public List<SelectListItem> CourseOptions { get; set; } = new List<SelectListItem>();

        public List<StudentCourses> EnrolledStudents { get; set; } = new List<StudentCourses>();

        public List<SelectListItem> AvailableStudents { get; set; } = new List<SelectListItem>();
    }
}
