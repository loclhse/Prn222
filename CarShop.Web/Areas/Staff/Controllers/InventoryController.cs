using AutoMapper;
using CarShop.BLL.Services;
using CarShop.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarShop.Web.Areas.Staff.Controllers
{
    [Area("Staff")]
    [Authorize(Roles = "Staff,Admin")]
    public class InventoryController : Controller
    {
        private readonly ICarService _service;
        private readonly IMapper _mapper;
        
        public InventoryController(ICarService service, IMapper mapper)
        {
            _service = service;
            _mapper = mapper;
        }
        
        public async Task<IActionResult> Index(int page = 1)
        {
            var (dtos, total) = await _service.GetCarsAsync(null, null, page, 20);
            
            // Map DTOs to ViewModels
            var viewModels = _mapper.Map<List<CarListViewModel>>(dtos);
            
            ViewBag.Total = total;
            ViewBag.Page = page;
            ViewBag.PageSize = 20;
            return View(viewModels);
        }
        
        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> AddStock(int id, int quantity)
        {
            await _service.AddStockAsync(id, Math.Max(1, quantity));
            TempData["Message"] = "Stock updated successfully!";
            return RedirectToAction(nameof(Index));
        }
    }
}
