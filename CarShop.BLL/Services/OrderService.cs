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
