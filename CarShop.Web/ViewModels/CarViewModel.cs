using System.ComponentModel.DataAnnotations;

namespace CarShop.Web.ViewModels
{
    public class CarViewModel
    {
        public int Id { get; set; }
        
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [StringLength(50)]
        public string Brand { get; set; } = string.Empty;
        
        [Required]
        [Range(0, 999999999)]
        public decimal Price { get; set; }
        
        [Required]
        [Range(0, 9999)]
        public int Stock { get; set; }
        
        public string? ImagePath { get; set; }
        
        [StringLength(500)]
        public string? Description { get; set; }
        
        public bool IsActive { get; set; }
    }
    
    public class CarListViewModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public string? ImagePath { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }
    
    public class CarDetailViewModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public string? ImagePath { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }
}
