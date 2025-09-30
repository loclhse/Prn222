using CarShop.BLL.DTOs;

namespace CarShop.BLL.Services
{
    public interface ICarService
    {
        Task<(IEnumerable<CarDto> items, int total)> GetCarsAsync(string? search, string? brand, int page, int pageSize);
        Task<CarDto?> GetByIdAsync(int id);
        Task<int> CreateAsync(CarDto dto);
        Task UpdateAsync(CarDto dto);
        Task DeleteAsync(int id);
        Task AddStockAsync(int id, int quantity);
    }
}
