using AutoMapper;
using CarShop.BLL.Services;
using CarShop.DAL.Entities;
using CarShop.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace CarShop.Web.Controllers
{
    [Authorize(Roles = "Customer")]
    public class CartController : Controller
    {
        private readonly ICarService _carService;
        private readonly IOrderService _orderService;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMapper _mapper;
        private const string CartSessionKey = "ShoppingCart";
        
        public CartController(ICarService carService, IOrderService orderService, 
            UserManager<ApplicationUser> um, IMapper mapper)
        {
            _carService = carService;
            _orderService = orderService;
            _userManager = um;
            _mapper = mapper;
        }
        
        public async Task<IActionResult> Index()
        {
            var cart = GetCart();
            var cartItems = new List<CartItemViewModel>();
            
            foreach (var item in cart)
            {
                var carDto = await _carService.GetByIdAsync(item.Key);
                if (carDto != null)
                {
                    cartItems.Add(new CartItemViewModel
                    {
                        CarId = carDto.Id,
                        CarName = carDto.Name,
                        Brand = carDto.Brand,
                        Price = carDto.Price,
                        Quantity = item.Value,
                        ImagePath = carDto.ImagePath,
                        Stock = carDto.Stock
                    });
                }
            }
            
            return View(cartItems);
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public IActionResult AddToCart(AddToCartViewModel model)
        {
            if (!ModelState.IsValid)
                return RedirectToAction("Details", "Cars", new { id = model.CarId });
            
            var cart = GetCart();
            
            if (cart.ContainsKey(model.CarId))
                cart[model.CarId] += model.Quantity;
            else
                cart[model.CarId] = model.Quantity;
            
            SaveCart(cart);
            TempData["Message"] = "Item added to cart!";
            return RedirectToAction("Index");
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public IActionResult UpdateQuantity(int carId, int quantity)
        {
            var cart = GetCart();
            
            if (quantity <= 0)
                cart.Remove(carId);
            else
                cart[carId] = quantity;
            
            SaveCart(cart);
            return RedirectToAction("Index");
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public IActionResult RemoveFromCart(int carId)
        {
            var cart = GetCart();
            cart.Remove(carId);
            SaveCart(cart);
            
            TempData["Message"] = "Item removed from cart.";
            return RedirectToAction("Index");
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Checkout()
        {
            var cart = GetCart();
            
            if (!cart.Any())
            {
                TempData["Error"] = "Your cart is empty.";
                return RedirectToAction("Index");
            }
            
            var user = await _userManager.GetUserAsync(User);
            if (user == null) return Unauthorized();
            
            var orderId = await _orderService.CheckoutAsync(user.Id, cart);
            
            HttpContext.Session.Remove(CartSessionKey);
            
            TempData["Message"] = $"Order placed successfully! Order #: {orderId}";
            return RedirectToAction("History", "Orders");
        }
        
        private Dictionary<int, int> GetCart()
        {
            var cartJson = HttpContext.Session.GetString(CartSessionKey);
            return string.IsNullOrEmpty(cartJson) 
                ? new Dictionary<int, int>() 
                : JsonSerializer.Deserialize<Dictionary<int, int>>(cartJson) ?? new Dictionary<int, int>();
        }
        
        private void SaveCart(Dictionary<int, int> cart)
        {
            var cartJson = JsonSerializer.Serialize(cart);
            HttpContext.Session.SetString(CartSessionKey, cartJson);
        }
    }
}
