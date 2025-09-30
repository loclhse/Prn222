Param(
  [string]$Root,
  [scriptblock]$WriteTextFunc
)

# Controllers with ViewModel mapping

$homeController = @'
using Microsoft.AspNetCore.Mvc;

namespace CarShop.Web.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index() => View();
    }
}
'@

$accountController = @'
using CarShop.DAL.Entities;
using CarShop.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace CarShop.Web.Controllers
{
    public class AccountController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        
        public AccountController(UserManager<ApplicationUser> um, SignInManager<ApplicationUser> sm)
        {
            _userManager = um;
            _signInManager = sm;
        }
        
        [AllowAnonymous]
        public IActionResult Register()
        {
            if (User.Identity?.IsAuthenticated == true)
                return RedirectToAction("Index", "Dashboard");
            return View(new RegisterViewModel());
        }
        
        [HttpPost, AllowAnonymous, ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(RegisterViewModel model)
        {
            if (User.Identity?.IsAuthenticated == true)
                return RedirectToAction("Index", "Dashboard");
                
            if (!ModelState.IsValid)
                return View(model);
                
            var user = new ApplicationUser
            {
                UserName = model.Email,
                Email = model.Email,
                FullName = model.FullName
            };
            
            var result = await _userManager.CreateAsync(user, model.Password);
            if (result.Succeeded)
            {
                await _userManager.AddToRoleAsync(user, "Customer");
                await _signInManager.SignInAsync(user, isPersistent: true);
                return RedirectToAction("Index", "Dashboard");
            }
            
            foreach (var error in result.Errors)
                ModelState.AddModelError("", error.Description);
                
            return View(model);
        }
        
        [AllowAnonymous]
        public IActionResult Login(string? returnUrl = null)
        {
            if (User.Identity?.IsAuthenticated == true)
                return RedirectToAction("Index", "Dashboard");
            ViewBag.ReturnUrl = returnUrl;
            return View(new LoginViewModel());
        }
        
        [HttpPost, AllowAnonymous, ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(LoginViewModel model, string? returnUrl = null)
        {
            if (User.Identity?.IsAuthenticated == true)
                return RedirectToAction("Index", "Dashboard");
                
            if (!ModelState.IsValid)
                return View(model);
                
            var result = await _signInManager.PasswordSignInAsync(
                model.Email, model.Password, true, false);
                
            if (result.Succeeded)
                return Redirect(returnUrl ?? Url.Action("Index", "Dashboard")!);
                
            ModelState.AddModelError("", "Invalid login attempt.");
            return View(model);
        }
        
        [Authorize]
        public async Task<IActionResult> Logout()
        {
            await _signInManager.SignOutAsync();
            return RedirectToAction("Index", "Home");
        }
        
        [AllowAnonymous]
        public IActionResult AccessDenied() => View();
    }
}
'@

$carsController = @'
using AutoMapper;
using CarShop.BLL.Services;
using CarShop.Web.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace CarShop.Web.Controllers
{
    public class CarsController : Controller
    {
        private readonly ICarService _service;
        private readonly IMapper _mapper;
        private const int PageSize = 9;
        
        public CarsController(ICarService service, IMapper mapper)
        {
            _service = service;
            _mapper = mapper;
        }
        
        public async Task<IActionResult> Index(string? search, string? brand, int page = 1)
        {
            var (items, total) = await _service.GetCarsAsync(search, brand, page, PageSize);
            
            // Map DTOs to ViewModels
            var viewModels = _mapper.Map<List<CarListViewModel>>(items);
            
            ViewBag.Total = total;
            ViewBag.Page = page;
            ViewBag.PageSize = PageSize;
            ViewBag.Search = search;
            ViewBag.Brand = brand;
            
            return View(viewModels);
        }
        
        public async Task<IActionResult> Details(int id)
        {
            var carDto = await _service.GetByIdAsync(id);
            if (carDto == null) return NotFound();
            
            // Map DTO to ViewModel
            var viewModel = _mapper.Map<CarDetailViewModel>(carDto);
            ViewBag.IsInactive = !carDto.IsActive;
            
            return View(viewModel);
        }
    }
}
'@

$cartController = @'
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
'@

$ordersController = @'
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
'@

$testDriveController = @'
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
    public class TestDriveController : Controller
    {
        private readonly ITestDriveService _service;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMapper _mapper;
        
        public TestDriveController(ITestDriveService service, UserManager<ApplicationUser> um, IMapper mapper)
        {
            _service = service;
            _userManager = um;
            _mapper = mapper;
        }
        
        public async Task<IActionResult> My()
        {
            var user = await _userManager.GetUserAsync(User);
            if (user == null) return Unauthorized();
            
            var dtos = await _service.GetMyAsync(user.Id);
            
            // Map DTOs to ViewModels
            var viewModels = _mapper.Map<List<TestDriveViewModel>>(dtos);
            
            return View(viewModels);
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(CreateTestDriveViewModel model)
        {
            if (!ModelState.IsValid)
            {
                TempData["Error"] = "Please fill in all required fields.";
                return RedirectToAction("Details", "Cars", new { id = model.CarId });
            }
            
            var user = await _userManager.GetUserAsync(User);
            if (user == null) return Unauthorized();
            
            var id = await _service.CreateAsync(user.Id, model.CarId, model.ScheduledAt, model.Notes);
            TempData["Message"] = $"Test drive appointment #{id} booked successfully!";
            return RedirectToAction(nameof(My));
        }
    }
}
'@

$dashboardController = @'
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarShop.Web.Controllers
{
    [Authorize]
    public class DashboardController : Controller
    {
        public IActionResult Index() => View();
    }
}
'@

# Write all controllers
& $WriteTextFunc -Path "$Root\CarShop.Web\Controllers\HomeController.cs" -Content $homeController
& $WriteTextFunc -Path "$Root\CarShop.Web\Controllers\AccountController.cs" -Content $accountController
& $WriteTextFunc -Path "$Root\CarShop.Web\Controllers\CarsController.cs" -Content $carsController
& $WriteTextFunc -Path "$Root\CarShop.Web\Controllers\CartController.cs" -Content $cartController
& $WriteTextFunc -Path "$Root\CarShop.Web\Controllers\OrdersController.cs" -Content $ordersController
& $WriteTextFunc -Path "$Root\CarShop.Web\Controllers\TestDriveController.cs" -Content $testDriveController
& $WriteTextFunc -Path "$Root\CarShop.Web\Controllers\DashboardController.cs" -Content $dashboardController

Write-Host "  Controllers with ViewModel mapping created" -ForegroundColor White