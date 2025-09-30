using AutoMapper;
using CarShop.BLL.Services;
using CarShop.DAL.Entities;
using CarShop.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace CarShop.Web.Controllers
{
    [Authorize(Roles = "Customer")]
    public class OrdersController : Controller
    {
        private readonly IOrderService _orderService;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMapper _mapper;
        
        public OrdersController(IOrderService orderService, UserManager<ApplicationUser> um, IMapper mapper)
        {
            _orderService = orderService;
            _userManager = um;
            _mapper = mapper;
        }
        
        public async Task<IActionResult> History()
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null) return Unauthorized();
            
            var orderDtos = await _orderService.GetOrdersAsync(user.Id);
            
            // Map DTOs to ViewModels
            var viewModels = _mapper.Map<List<OrderViewModel>>(orderDtos);
            
            return View(viewModels);
        }
    }
}
