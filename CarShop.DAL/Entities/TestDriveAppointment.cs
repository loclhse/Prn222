namespace CarShop.DAL.Entities
{
    public enum AppointmentStatus { Requested, Confirmed, Completed, Cancelled }
    
    public class TestDriveAppointment
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public int CarId { get; set; }
        public Car Car { get; set; } = null!;
        public DateTime ScheduledAt { get; set; }
        public AppointmentStatus Status { get; set; } = AppointmentStatus.Requested;
        public string? Notes { get; set; }
    }
}
