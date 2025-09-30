using CarShop.BLL.DTOs;

namespace CarShop.BLL.Services
{
    public interface IOrderService
    {
        Task<int> CheckoutAsync(string userId, Dictionary<int, int> cart);
        Task<IEnumerable<OrderDto>> GetOrdersAsync(string userId);
    }
}
