using System.ComponentModel.DataAnnotations;

namespace CarShop.Web.ViewModels
{
    public class TestDriveViewModel
    {
        public int Id { get; set; }
        public int CarId { get; set; }
        public string CarName { get; set; } = string.Empty;
        public DateTime ScheduledAt { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Notes { get; set; }
    }
    
    public class CreateTestDriveViewModel
    {
        [Required]
        public int CarId { get; set; }
        
        [Required]
        public DateTime ScheduledAt { get; set; }
        
        [StringLength(500)]
        public string? Notes { get; set; }
    }
}
