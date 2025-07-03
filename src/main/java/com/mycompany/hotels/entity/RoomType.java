package com.mycompany.hotels.entity;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Set;
import javax.persistence.*;

@Entity
@Table(name = "room_types")
public class RoomType implements Serializable {
    private static final long serialVersionUID = 1L;
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "room_type_id")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hotel_id", nullable = false)
    private Hotel hotel;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "description")
    private String description;

    @Column(name = "max_guests", nullable = false)
    private Integer maxGuests;

    @Column(name = "base_price", nullable = false)
    private BigDecimal basePrice;

    @OneToMany(mappedBy = "roomType")
    private Set<Room> rooms = new HashSet<>();
    
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
      name = "room_type_amenities",
      joinColumns = @JoinColumn(name = "room_type_id"),
      inverseJoinColumns = @JoinColumn(name = "amenity_id")
    )
    private Set<RoomAmenity> amenities = new HashSet<>();

    public RoomType() {
    }
    
    public RoomType(Hotel hotel, String name, Integer maxGuests, BigDecimal basePrice) {
        this.hotel = hotel;
        this.name = name;
        this.maxGuests = maxGuests;
        this.basePrice = basePrice;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Hotel getHotel() {
        return hotel;
    }

    public void setHotel(Hotel hotel) {
        this.hotel = hotel;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getMaxGuests() {
        return maxGuests;
    }

    public void setMaxGuests(Integer maxGuests) {
        this.maxGuests = maxGuests;
    }

    public BigDecimal getBasePrice() {
        return basePrice;
    }

    public void setBasePrice(BigDecimal basePrice) {
        this.basePrice = basePrice;
    }

    public Set<Room> getRooms() {
        return rooms;
    }

    public void setRooms(Set<Room> rooms) {
        this.rooms = rooms;
    }

    @Override
    public int hashCode() {
        int hash = 0;
        hash += (id != null ? id.hashCode() : 0);
        return hash;
    }

    @Override
    public boolean equals(Object object) {
        if (!(object instanceof RoomType)) {
            return false;
        }
        RoomType other = (RoomType) object;
        return (this.id != null || other.id == null) && (this.id == null || this.id.equals(other.id));
    }

    @Override
    public String toString() {
        return "RoomType[id=" + id + ", name=" + name + "]";
    }

    public Set<RoomAmenity> getAmenities() {
        return amenities;
    }

    public void setAmenities(Set<RoomAmenity> amenities) {
        this.amenities = amenities;
    }
    
    public void addAmenity(RoomAmenity amenity) {
        this.amenities.add(amenity);
        amenity.getRoomTypes().add(this);
    }
    
    public void removeAmenity(RoomAmenity amenity) {
        this.amenities.remove(amenity);
        amenity.getRoomTypes().remove(this);
    }
}