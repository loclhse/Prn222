using CarShop.DAL.Entities;
using CarShop.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace CarShop.Web.Controllers
{
    public class AccountController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly ILogger<AccountController> _logger;
        
        public AccountController(UserManager<ApplicationUser> um, SignInManager<ApplicationUser> sm, ILogger<AccountController> logger)
        {
            _userManager = um;
            _signInManager = sm;
            _logger = logger;
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
            {
                foreach (var key in ModelState.Keys)
                {
                    var errors = ModelState[key].Errors;
                    foreach (var error in errors)
                    {
                        _logger.LogWarning($"ModelState error for {key}: {error.ErrorMessage}");
                    }
                }
                return View(model);
            }
            
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
            {
                _logger.LogError($"Register error: {error.Code} - {error.Description}");
                ModelState.AddModelError("", error.Description);
            }
            
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
