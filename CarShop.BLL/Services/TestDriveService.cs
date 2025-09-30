using CarShop.BLL.DTOs;
using CarShop.DAL;
using CarShop.DAL.Entities;
using Microsoft.EntityFrameworkCore;

namespace CarShop.BLL.Services
{
    public class TestDriveService : ITestDriveService
    {
        private readonly AppDbContext _context;
        
        public TestDriveService(AppDbContext context)
        {
            _context = context;
        }
        
        public async Task<int> CreateAsync(string userId, int carId, DateTime scheduledAt, string? notes)
        {
            var appointment = new TestDriveAppointment
            {
                UserId = userId,
                CarId = carId,
                ScheduledAt = scheduledAt,
                Notes = notes,
                Status = AppointmentStatus.Requested
            };
            
            _context.TestDriveAppointments.Add(appointment);
            await _context.SaveChangesAsync();
            return appointment.Id;
        }
        
        public async Task<IEnumerable<TestDriveDto>> GetMyAsync(string userId)
        {
            var appointments = await _context.TestDriveAppointments
                .Include(a => a.Car)
                .Where(a => a.UserId == userId)
                .OrderByDescending(a => a.ScheduledAt)
                .ToListAsync();
                
            return appointments.Select(a => new TestDriveDto
            {
                Id = a.Id,
                CarId = a.CarId,
                CarName = a.Car?.Name ?? "Unknown",
                ScheduledAt = a.ScheduledAt,
                Status = a.Status.ToString(),
                Notes = a.Notes
            });
        }
        
        public async Task<IEnumerable<TestDriveDto>> GetAllAsync()
        {
            var appointments = await _context.TestDriveAppointments
                .Include(a => a.Car)
                .OrderByDescending(a => a.ScheduledAt)
                .ToListAsync();
                
            return appointments.Select(a => new TestDriveDto
            {
                Id = a.Id,
                CarId = a.CarId,
                CarName = a.Car?.Name ?? "Unknown",
                ScheduledAt = a.ScheduledAt,
                Status = a.Status.ToString(),
                Notes = a.Notes
            });
        }
        
        public async Task ConfirmAsync(int id)
        {
            var appointment = await _context.TestDriveAppointments.FindAsync(id);
            if (appointment != null)
            {
                appointment.Status = AppointmentStatus.Confirmed;
                await _context.SaveChangesAsync();
            }
        }
    }
}
