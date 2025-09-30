using Microsoft.AspNetCore.Identity;

namespace CarShop.DAL.Entities
{
    public class ApplicationUser : IdentityUser
    {
        public string? FullName { get; set; }
        public string? Address { get; set; }
    }
}
