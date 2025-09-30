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
