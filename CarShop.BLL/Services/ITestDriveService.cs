using CarShop.BLL.DTOs;

namespace CarShop.BLL.Services
{
    public interface ITestDriveService
    {
        Task<int> CreateAsync(string userId, int carId, DateTime scheduledAt, string? notes);
        Task<IEnumerable<TestDriveDto>> GetMyAsync(string userId);
        Task<IEnumerable<TestDriveDto>> GetAllAsync();
        Task ConfirmAsync(int id);
    }
}
