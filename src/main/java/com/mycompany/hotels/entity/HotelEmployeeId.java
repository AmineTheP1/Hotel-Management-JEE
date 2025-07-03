// src/main/java/com/mycompany/hotels/entity/HotelEmployeeId.java
package com.mycompany.hotels.entity;

import java.io.Serializable;
import java.util.Objects;

import javax.persistence.Column;
import javax.persistence.Embeddable;

@Embeddable
public class HotelEmployeeId implements Serializable {
    private static final long serialVersionUID = 1L;

    @Column(name = "hotel_id")
    private Long hotelId;

    @Column(name = "user_id")
    private Long userId;

    public HotelEmployeeId() {}

    public HotelEmployeeId(Long hotelId, Long userId) {
        this.hotelId = hotelId;
        this.userId  = userId;
    }

    public Long getHotelId() { return hotelId; }
    public void setHotelId(Long hotelId) { this.hotelId = hotelId; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof HotelEmployeeId)) return false;
        HotelEmployeeId that = (HotelEmployeeId) o;
        return Objects.equals(hotelId, that.hotelId) &&
               Objects.equals(userId,  that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(hotelId, userId);
    }
}
