Param(
  [string]$Root,
  [string]$ConnectionString,
  [scriptblock]$WriteTextFunc
)

# DAL Project (no changes needed)
$dalCsproj = @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="9.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="9.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="9.0.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.Configuration" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection.Abstractions" Version="9.0.0" />
  </ItemGroup>
  <ItemGroup>
    <None Update="appsettings.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
'@

$dalAppsettings = (@{
  ConnectionStrings = @{ DefaultConnection = $ConnectionString }
} | ConvertTo-Json -Depth 5)

$applicationUser = @'
using Microsoft.AspNetCore.Identity;

namespace CarShop.DAL.Entities
{
    public class ApplicationUser : IdentityUser
    {
        public string? FullName { get; set; }
        public string? Address { get; set; }
    }
}
'@

$car = @'
namespace CarShop.DAL.Entities
{
    public class Car
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public string? ImagePath { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
'@

$order = @'
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
'@

$appointment = @'
namespace CarShop.DAL.Entities
{
    public enum AppointmentStatus { Requested, Confirmed, Completed, Cancelled }
    
    public class TestDriveAppointment
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public int CarId { get; set; }
        public Car Car { get; set; } = null!;
        public DateTime ScheduledAt { get; set; }
        public AppointmentStatus Status { get; set; } = AppointmentStatus.Requested;
        public string? Notes { get; set; }
    }
}
'@

$appDbContext = @'
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
'@

$seeder = @'
using CarShop.DAL.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace CarShop.DAL
{
    public static class Seeder
    {
        public static async Task SeedAsync(IServiceProvider sp)
        {
            using var scope = sp.CreateScope();
            var ctx = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            await ctx.Database.MigrateAsync();

            var roleMgr = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
            var userMgr = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

            string[] roles = new[] { "Admin", "Staff", "Customer" };
            foreach (var r in roles)
                if (!await roleMgr.RoleExistsAsync(r))
                    await roleMgr.CreateAsync(new IdentityRole(r));

            async Task EnsureUser(string email, string role, string fullName)
            {
                var u = await userMgr.FindByEmailAsync(email);
                if (u == null)
                {
                    u = new ApplicationUser 
                    { 
                        UserName = email, 
                        Email = email, 
                        EmailConfirmed = true, 
                        FullName = fullName 
                    };
                    await userMgr.CreateAsync(u, "P@ssword123");
                    await userMgr.AddToRoleAsync(u, role);
                }
            }

            await EnsureUser("admin@carshop.local", "Admin", "Admin User");
            await EnsureUser("staff@carshop.local", "Staff", "Staff Member");
            await EnsureUser("user@carshop.local", "Customer", "John Doe");

            if (!await ctx.Cars.AnyAsync())
            {
                ctx.Cars.AddRange(
                    new Car { Name = "Civic", Brand = "Honda", Price = 25000, Stock = 5, Description = "Reliable and fuel-efficient compact sedan." },
                    new Car { Name = "Corolla", Brand = "Toyota", Price = 24000, Stock = 7, Description = "World's best-selling car with proven reliability." },
                    new Car { Name = "Model 3", Brand = "Tesla", Price = 42000, Stock = 3, Description = "Electric sedan with autopilot capabilities." },
                    new Car { Name = "Mustang", Brand = "Ford", Price = 55000, Stock = 2, Description = "Iconic American muscle car with powerful V8." },
                    new Car { Name = "Camry", Brand = "Toyota", Price = 28000, Stock = 6, Description = "Premium midsize sedan with luxury features." },
                    new Car { Name = "Accord", Brand = "Honda", Price = 27500, Stock = 4, Description = "Spacious family sedan with advanced safety." }
                );
                await ctx.SaveChangesAsync();
            }
        }
    }
}
'@

$factory = @'
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace CarShop.DAL
{
    public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
    {
        public AppDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
            var basePath = Directory.GetCurrentDirectory();
            var configFile = Path.Combine(basePath, "appsettings.json");
            string? cs = null;
            
            if (File.Exists(configFile))
            {
                var configuration = new ConfigurationBuilder()
                    .SetBasePath(basePath)
                    .AddJsonFile("appsettings.json", optional: false)
                    .Build();
                cs = configuration.GetConnectionString("DefaultConnection");
            }

            cs ??= "Server=.;Database=CarShopDb;User Id=sa;Password=123;TrustServerCertificate=True;MultipleActiveResultSets=true";
            optionsBuilder.UseSqlServer(cs);
            return new AppDbContext(optionsBuilder.Options);
        }
    }
}
'@

# Write files
& $WriteTextFunc -Path "$Root\CarShop.DAL\CarShop.DAL.csproj" -Content $dalCsproj
& $WriteTextFunc -Path "$Root\CarShop.DAL\appsettings.json" -Content $dalAppsettings
& $WriteTextFunc -Path "$Root\CarShop.DAL\Entities\ApplicationUser.cs" -Content $applicationUser
& $WriteTextFunc -Path "$Root\CarShop.DAL\Entities\Car.cs" -Content $car
& $WriteTextFunc -Path "$Root\CarShop.DAL\Entities\Order.cs" -Content $order
& $WriteTextFunc -Path "$Root\CarShop.DAL\Entities\TestDriveAppointment.cs" -Content $appointment
& $WriteTextFunc -Path "$Root\CarShop.DAL\AppDbContext.cs" -Content $appDbContext
& $WriteTextFunc -Path "$Root\CarShop.DAL\Seeder.cs" -Content $seeder
& $WriteTextFunc -Path "$Root\CarShop.DAL\AppDbContextFactory.cs" -Content $factory