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
