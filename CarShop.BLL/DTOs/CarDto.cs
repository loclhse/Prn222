namespace CarShop.BLL.DTOs
{
    public class CarDto
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
