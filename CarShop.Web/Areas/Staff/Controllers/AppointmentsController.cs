using AutoMapper;
using CarShop.BLL.Services;
using CarShop.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarShop.Web.Areas.Staff.Controllers
{
    [Area("Staff")]
    [Authorize(Roles = "Staff,Admin")]
    public class AppointmentsController : Controller
    {
        private readonly ITestDriveService _service;
        private readonly IMapper _mapper;
        
        public AppointmentsController(ITestDriveService service, IMapper mapper)
        {
            _service = service;
            _mapper = mapper;
        }
        
        public async Task<IActionResult> Index()
        {
            var dtos = await _service.GetAllAsync();
            
            // Map DTOs to ViewModels
            var viewModels = _mapper.Map<List<TestDriveViewModel>>(dtos);
            
            return View(viewModels);
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Confirm(int id)
        {
            await _service.ConfirmAsync(id);
            TempData["Message"] = "Appointment confirmed successfully!";
            return RedirectToAction(nameof(Index));
        }
    }
}
