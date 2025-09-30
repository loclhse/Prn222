using AutoMapper;
using CarShop.BLL.DTOs;
using CarShop.Web.ViewModels;

namespace CarShop.Web.Mappings
{
    public class WebMappingProfile : Profile
    {
        public WebMappingProfile()
        {
            // Car mappings
            CreateMap<CarDto, CarViewModel>().ReverseMap();
            CreateMap<CarDto, CarListViewModel>();
            CreateMap<CarDto, CarDetailViewModel>();
            
            // Order mappings
            CreateMap<OrderDto, OrderViewModel>();
            CreateMap<OrderItemDto, OrderItemViewModel>();
            
            // TestDrive mappings
            CreateMap<TestDriveDto, TestDriveViewModel>();
            CreateMap<CreateTestDriveViewModel, TestDriveDto>();
        }
    }
}
