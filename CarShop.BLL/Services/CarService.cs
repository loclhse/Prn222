using AutoMapper;
using CarShop.BLL.DTOs;
using CarShop.DAL;
using CarShop.DAL.Entities;
using Microsoft.EntityFrameworkCore;

namespace CarShop.BLL.Services
{
    public class CarService : ICarService
    {
        private readonly AppDbContext _context;
        private readonly IMapper _mapper;
        
        public CarService(AppDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }
        
        public async Task<(IEnumerable<CarDto> items, int total)> GetCarsAsync(string? search, string? brand, int page, int pageSize)
        {
            var query = _context.Cars.AsQueryable();
            
            // Only show active cars in listing
            query = query.Where(c => c.IsActive);
            
            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.ToLower().Trim();
                query = query.Where(c => c.Name.ToLower().Contains(search) || 
                                        (c.Description ?? "").ToLower().Contains(search));
            }
            
            if (!string.IsNullOrWhiteSpace(brand))
            {
                brand = brand.ToLower().Trim();
                query = query.Where(c => c.Brand.ToLower().Contains(brand));
            }
            
            int total = await query.CountAsync();
            var items = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
            
            return (_mapper.Map<IEnumerable<CarDto>>(items), total);
        }
        
        public async Task<CarDto?> GetByIdAsync(int id)
        {
            var car = await _context.Cars.FindAsync(id);
            return car == null ? null : _mapper.Map<CarDto>(car);
        }
        
        public async Task<int> CreateAsync(CarDto dto)
        {
            var car = _mapper.Map<Car>(dto);
            _context.Cars.Add(car);
            await _context.SaveChangesAsync();
            return car.Id;
        }
        
        public async Task UpdateAsync(CarDto dto)
        {
            var car = _mapper.Map<Car>(dto);
            _context.Cars.Update(car);
            await _context.SaveChangesAsync();
        }
        
        public async Task DeleteAsync(int id)
        {
            var car = await _context.Cars.FindAsync(id);
            if (car != null)
            {
                // Soft delete
                car.IsActive = false;
                await _context.SaveChangesAsync();
            }
        }
        
        public async Task AddStockAsync(int id, int quantity)
        {
            var car = await _context.Cars.FindAsync(id);
            if (car != null)
            {
                car.Stock += Math.Max(1, quantity);
                await _context.SaveChangesAsync();
            }
        }
    }
}
