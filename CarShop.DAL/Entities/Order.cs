namespace CarShop.DAL.Entities
{
    public enum OrderStatus { PendingPayment, Paid, Processing, Shipping, Completed, Cancelled }
    
    public class Order
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public OrderStatus Status { get; set; } = OrderStatus.Paid;
        public decimal Total { get; set; }
        public List<OrderItem> Items { get; set; } = new();
    }
    
    public class OrderItem
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public Order Order { get; set; } = null!;
        public int CarId { get; set; }
        public Car Car { get; set; } = null!;
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }
}
