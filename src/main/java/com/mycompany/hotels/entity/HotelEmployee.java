// src/main/java/com/mycompany/hotels/entity/HotelEmployee.java
package com.mycompany.hotels.entity;

import java.io.Serializable;
import java.time.LocalDate;

import javax.persistence.Column;
import javax.persistence.EmbeddedId;
import javax.persistence.Entity;
import javax.persistence.EnumType;
import javax.persistence.Enumerated;
import javax.persistence.FetchType;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.MapsId;
import javax.persistence.Table;

@Entity
@Table(name = "hotel_employees")
public class HotelEmployee implements Serializable {
    private static final long serialVersionUID = 1L;

    @EmbeddedId
    private HotelEmployeeId id;

    @MapsId("hotelId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hotel_id")
    private Hotel hotel;

    @MapsId("userId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "position", nullable = false)
    private EmployeePosition position;

    @Column(name = "hired_at", nullable = false)
    private LocalDate hiredAt;

    public HotelEmployee() {
        this.hiredAt = LocalDate.now();
    }

    public HotelEmployee(Hotel hotel, User user, EmployeePosition position) {
        this();
        this.hotel    = hotel;
        this.user     = user;
        this.position = position;
        this.id       = new HotelEmployeeId();  // JPA fills in the IDs when persisting
    }

    public HotelEmployeeId getId()              { return id; }
    public Hotel getHotel()                     { return hotel; }
    public User getUser()                       { return user; }
    public EmployeePosition getPosition()       { return position; }
    public LocalDate getHiredAt()               { return hiredAt; }

    public void setHotel(Hotel hotel) {
        this.hotel = hotel;
        if (id == null) id = new HotelEmployeeId();
        id.setHotelId(hotel.getId());
    }

    public void setUser(User user) {
        this.user = user;
        if (id == null) id = new HotelEmployeeId();
        id.setUserId(user.getId());
    }

    public void setPosition(EmployeePosition position) {
        this.position = position;
    }

    public void setHiredAt(LocalDate hiredAt) {
        this.hiredAt = hiredAt;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof HotelEmployee)) return false;
        HotelEmployee that = (HotelEmployee) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }

    @Override
    public String toString() {
        return "HotelEmployee[id=" + id + ", position=" + position + "]";
    }
}
