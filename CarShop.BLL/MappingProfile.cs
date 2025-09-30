using AutoMapper;
using CarShop.BLL.DTOs;
using CarShop.DAL.Entities;

namespace CarShop.BLL
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Car, CarDto>().ReverseMap();
            
            CreateMap<OrderItem, OrderItemDto>()
                .ForMember(d => d.CarName, o => o.MapFrom(s => s.Car.Name));
            
            CreateMap<Order, OrderDto>()
                .ForMember(d => d.Status, o => o.MapFrom(s => s.Status.ToString()));
            
            CreateMap<TestDriveAppointment, TestDriveDto>()
                .ForMember(d => d.CarName, o => o.MapFrom(s => s.Car.Name))
                .ForMember(d => d.Status, o => o.MapFrom(s => s.Status.ToString()));
        }
    }
}
