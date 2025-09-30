Param(
  [string]$Root,
  [scriptblock]$WriteTextFunc
)

$bllCsproj = @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\CarShop.DAL\CarShop.DAL.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="AutoMapper" Version="12.0.1" />
    <PackageReference Include="AutoMapper.Extensions.Microsoft.DependencyInjection" Version="12.0.1" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection.Abstractions" Version="9.0.0" />
  </ItemGroup>
</Project>
'@

# DTOs
$carDto = @'
namespace CarShop.BLL.DTOs
{
    public class CarDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public string? ImagePath { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }
}
'@

$orderDto = @'
namespace CarShop.BLL.DTOs
{
    public class OrderDto
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; }
        public decimal Total { get; set; }
        public string Status { get; set; } = string.Empty;
        public List<OrderItemDto> Items { get; set; } = new();
    }
    
    public class OrderItemDto
    {
        public int CarId { get; set; }
        public string CarName { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }
}
'@

$testDriveDto = @'
namespace CarShop.BLL.DTOs
{
    public class TestDriveDto
    {
        public int Id { get; set; }
        public int CarId { get; set; }
        public string CarName { get; set; } = string.Empty;
        public DateTime ScheduledAt { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Notes { get; set; }
    }
}
'@

# AutoMapper Profile
$mappingProfile = @'
using AutoMapper;
using CarShop.BLL.DTOs;
using CarShop.DAL.Entities;

namespace CarShop.BLL
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Car, CarDto>().ReverseMap();
            
            CreateMap<OrderItem, OrderItemDto>()
                .ForMember(d => d.CarName, o => o.MapFrom(s => s.Car.Name));
            
            CreateMap<Order, OrderDto>()
                .ForMember(d => d.Status, o => o.MapFrom(s => s.Status.ToString()));
            
            CreateMap<TestDriveAppointment, TestDriveDto>()
                .ForMember(d => d.CarName, o => o.MapFrom(s => s.Car.Name))
                .ForMember(d => d.Status, o => o.MapFrom(s => s.Status.ToString()));
        }
    }
}
'@

# Car Service
$iCarService = @'
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
'@

$carService = @'
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
'@

# Order Service
$iOrderService = @'
using CarShop.BLL.DTOs;

namespace CarShop.BLL.Services
{
    public interface IOrderService
    {
        Task<int> CheckoutAsync(string userId, Dictionary<int, int> cart);
        Task<IEnumerable<OrderDto>> GetOrdersAsync(string userId);
    }
}
'@

$orderService = @'
using CarShop.BLL.DTOs;
using CarShop.DAL;
using CarShop.DAL.Entities;
using Microsoft.EntityFrameworkCore;

namespace CarShop.BLL.Services
{
    public class OrderService : IOrderService
    {
        private readonly AppDbContext _context;
        
        public OrderService(AppDbContext context)
        {
            _context = context;
        }
        
        public async Task<int> CheckoutAsync(string userId, Dictionary<int, int> cart)
        {
            var order = new Order
            {
                UserId = userId,
                Status = OrderStatus.Paid,
                CreatedAt = DateTime.UtcNow,
                Items = new()
            };
            
            decimal total = 0;
            foreach (var kv in cart)
            {
                var car = await _context.Cars.FindAsync(kv.Key);
                if (car == null) continue;
                
                var qty = Math.Max(1, kv.Value);
                if (car.Stock < qty) qty = car.Stock;
                if (qty <= 0) continue;
                
                car.Stock -= qty;
                order.Items.Add(new OrderItem
                {
                    CarId = car.Id,
                    Quantity = qty,
                    UnitPrice = car.Price
                });
                total += car.Price * qty;
            }
            
            order.Total = total;
            _context.Orders.Add(order);
            await _context.SaveChangesAsync();
            return order.Id;
        }
        
        public async Task<IEnumerable<OrderDto>> GetOrdersAsync(string userId)
        {
            var orders = await _context.Orders
                .Include(o => o.Items)
                    .ThenInclude(i => i.Car)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
                
            return orders.Select(o => new OrderDto
            {
                Id = o.Id,
                CreatedAt = o.CreatedAt,
                Total = o.Total,
                Status = o.Status.ToString(),
                Items = o.Items.Select(i => new OrderItemDto
                {
                    CarId = i.CarId,
                    CarName = i.Car?.Name ?? "Unknown",
                    Quantity = i.Quantity,
                    UnitPrice = i.UnitPrice
                }).ToList()
            });
        }
    }
}
'@

# Test Drive Service
$iTestDriveService = @'
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
'@

$testDriveService = @'
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
'@

# Write files
& $WriteTextFunc -Path "$Root\CarShop.BLL\CarShop.BLL.csproj" -Content $bllCsproj
& $WriteTextFunc -Path "$Root\CarShop.BLL\DTOs\CarDto.cs" -Content $carDto
& $WriteTextFunc -Path "$Root\CarShop.BLL\DTOs\OrderDto.cs" -Content $orderDto
& $WriteTextFunc -Path "$Root\CarShop.BLL\DTOs\TestDriveDto.cs" -Content $testDriveDto
& $WriteTextFunc -Path "$Root\CarShop.BLL\MappingProfile.cs" -Content $mappingProfile
& $WriteTextFunc -Path "$Root\CarShop.BLL\Services\ICarService.cs" -Content $iCarService
& $WriteTextFunc -Path "$Root\CarShop.BLL\Services\CarService.cs" -Content $carService
& $WriteTextFunc -Path "$Root\CarShop.BLL\Services\IOrderService.cs" -Content $iOrderService
& $WriteTextFunc -Path "$Root\CarShop.BLL\Services\OrderService.cs" -Content $orderService
& $WriteTextFunc -Path "$Root\CarShop.BLL\Services\ITestDriveService.cs" -Content $iTestDriveService
& $WriteTextFunc -Path "$Root\CarShop.BLL\Services\TestDriveService.cs" -Content $testDriveService