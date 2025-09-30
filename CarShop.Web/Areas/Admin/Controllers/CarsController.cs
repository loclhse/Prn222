using AutoMapper;
using CarShop.BLL.Services;
using CarShop.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarShop.Web.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class CarsController : Controller
    {
        private readonly ICarService _service;
        private readonly IWebHostEnvironment _env;
        private readonly IMapper _mapper;
        
        public CarsController(ICarService service, IWebHostEnvironment env, IMapper mapper)
        {
            _service = service;
            _env = env;
            _mapper = mapper;
        }
        
        public async Task<IActionResult> Index(int page = 1)
        {
            // Get all cars including inactive ones for admin
            var (dtos, total) = await _service.GetCarsAsync(null, null, page, 20);
            
            // Map DTOs to ViewModels
            var viewModels = _mapper.Map<List<CarViewModel>>(dtos);
            
            ViewBag.Total = total;
            ViewBag.Page = page;
            ViewBag.PageSize = 20;
            return View(viewModels);
        }
        
        public IActionResult Create()
        {
            return View(new CarViewModel { IsActive = true });
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(CarViewModel model, IFormFile? image)
        {
            if (!ModelState.IsValid)
                return View(model);
            
            model.ImagePath = await SaveImageAsync(image);
            
            // Map ViewModel to DTO
            var dto = _mapper.Map<CarShop.BLL.DTOs.CarDto>(model);
            await _service.CreateAsync(dto);
            
            TempData["Message"] = "Car created successfully!";
            return RedirectToAction(nameof(Index));
        }
        
        public async Task<IActionResult> Edit(int id)
        {
            var dto = await _service.GetByIdAsync(id);
            if (dto == null) return NotFound();
            
            // Map DTO to ViewModel
            var model = _mapper.Map<CarViewModel>(dto);
            return View(model);
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(CarViewModel model, IFormFile? image)
        {
            if (!ModelState.IsValid)
                return View(model);
            
            var newPath = await SaveImageAsync(image);
            if (!string.IsNullOrEmpty(newPath))
                model.ImagePath = newPath;
            
            // Map ViewModel to DTO
            var dto = _mapper.Map<CarShop.BLL.DTOs.CarDto>(model);
            await _service.UpdateAsync(dto);
            
            TempData["Message"] = "Car updated successfully!";
            return RedirectToAction(nameof(Index));
        }
        
        public async Task<IActionResult> Delete(int id)
        {
            var dto = await _service.GetByIdAsync(id);
            if (dto == null) return NotFound();
            
            // Map DTO to ViewModel
            var model = _mapper.Map<CarViewModel>(dto);
            return View(model);
        }
        
        [HttpPost, ActionName("Delete"), ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            await _service.DeleteAsync(id);
            TempData["Message"] = "Car deactivated successfully!";
            return RedirectToAction(nameof(Index));
        }
        
        private async Task<string?> SaveImageAsync(IFormFile? file)
        {
            if (file == null || file.Length == 0)
                return null;
            
            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            
            if (!allowed.Contains(ext))
            {
                ModelState.AddModelError("", "Invalid image format.");
                return null;
            }
            
            if (file.Length > 5 * 1024 * 1024)
            {
                ModelState.AddModelError("", "Image too large (max 5MB).");
                return null;
            }
            
            var uploads = Path.Combine(_env.WebRootPath, "uploads");
            Directory.CreateDirectory(uploads);
            
            var fileName = $"{Guid.NewGuid()}{ext}";
            var path = Path.Combine(uploads, fileName);
            
            using var stream = new FileStream(path, FileMode.Create);
            await file.CopyToAsync(stream);
            
            return "/uploads/" + fileName;
        }
    }
}
