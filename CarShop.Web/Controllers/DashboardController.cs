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
