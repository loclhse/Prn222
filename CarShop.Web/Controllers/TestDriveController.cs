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
