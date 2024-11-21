namespace IdentityApiAuth.Models;

public class PostModel
{
    public string Description { get; set; }
    public decimal CurrentPrice { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public int MaxPeople { get; set; }
    public UserModel Creator { get; set; }
}