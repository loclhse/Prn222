namespace CarShop.Web.ViewModels
{
    public class CartItemViewModel
    {
        public int CarId { get; set; }
        public string CarName { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Quantity { get; set; }
        public string? ImagePath { get; set; }
        public int Stock { get; set; }
        public decimal Subtotal => Price * Quantity;
    }
    
    public class AddToCartViewModel
    {
        public int CarId { get; set; }
        public int Quantity { get; set; } = 1;
    }
}
