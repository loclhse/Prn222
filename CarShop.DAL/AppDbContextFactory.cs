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

            
            optionsBuilder.UseSqlServer(cs);
            return new AppDbContext(optionsBuilder.Options);
        }
    }
}
