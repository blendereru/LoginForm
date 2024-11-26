using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace IdentityApiAuth.Models;

public class ApplicationContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationContext(DbContextOptions<ApplicationContext> opts) : base(opts) { }
    public DbSet<Post> Posts { get; set; } = null!;
    public DbSet<RefreshSession> RefreshSessions { get; set; } = null!;
    public DbSet<Event> Events { get; set; } = null!;
    public DbSet<Subscription> Subscriptions { get; set; } = null!;
    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.Entity<RefreshSession>()
            .HasOne(r => r.User)
            .WithMany(u => u.RefreshSessions)
            .OnDelete(DeleteBehavior.Cascade);
        builder.Entity<RefreshSession>(r =>
        {
            r.Property(p => p.UA).HasMaxLength(200);
            r.Property(p => p.Ip).HasMaxLength(15);
        });
        builder.Entity<Post>(entity =>
        {
            entity.Property(p => p.Latitude)
                .HasColumnType("decimal(9,6)");
            entity.Property(p => p.Longitude)
                .HasColumnType("decimal(9,6)");
        });
        builder.Entity<Post>()
            .HasMany(p => p.Members)
            .WithMany(u => u.Posts);
    }
}