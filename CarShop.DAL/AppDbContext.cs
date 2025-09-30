using CarShop.DAL.Entities;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace CarShop.DAL
{
    public class AppDbContext : IdentityDbContext<ApplicationUser>
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
        
        public DbSet<Car> Cars => Set<Car>();
        public DbSet<Order> Orders => Set<Order>();
        public DbSet<OrderItem> OrderItems => Set<OrderItem>();
        public DbSet<TestDriveAppointment> TestDriveAppointments => Set<TestDriveAppointment>();

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            builder.Entity<OrderItem>()
                   .HasOne(oi => oi.Car)
                   .WithMany()
                   .HasForeignKey(oi => oi.CarId);

            builder.Entity<Car>().Property(c => c.Price).HasPrecision(18, 2);
            builder.Entity<Order>().Property(o => o.Total).HasPrecision(18, 2);
            builder.Entity<OrderItem>().Property(oi => oi.UnitPrice).HasPrecision(18, 2);
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                var config = new ConfigurationBuilder()
                    .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
                    .AddJsonFile("appsettings.json", optional: true)
                    .Build();
                var cs = config.GetConnectionString("DefaultConnection");
                if (!string.IsNullOrWhiteSpace(cs))
                    optionsBuilder.UseSqlServer(cs);
            }
        }
    }
}
