package com.mycompany.hotels.entity;

import java.io.Serializable;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import javax.persistence.*;

@Entity
@Table(name = "rooms")
public class Room implements Serializable {
    private static final long serialVersionUID = 1L;
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "room_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hotel_id", nullable = false)
    private Hotel hotel;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_type_id", nullable = false)
    private RoomType roomType;

    @Column(name = "room_number", nullable = false)
    private String roomNumber;

    @Column(name = "floor")
    private Integer floor;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private RoomStatus status;

    @Column(name = "last_status_at", nullable = false)
    private Instant lastStatusAt;

    @OneToMany(mappedBy = "room")
    private Set<RoomStatusHistory> statusHistory = new HashSet<>();

    public Room() {
        this.lastStatusAt = Instant.now();
        this.status = RoomStatus.available;
    }
    
    public Room(Hotel hotel, RoomType roomType, String roomNumber, Integer floor) {
        this();
        this.hotel = hotel;
        this.roomType = roomType;
        this.roomNumber = roomNumber;
        this.floor = floor;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Hotel getHotel() {
        return hotel;
    }

    public void setHotel(Hotel hotel) {
        this.hotel = hotel;
    }

    public RoomType getRoomType() {
        return roomType;
    }

    public void setRoomType(RoomType roomType) {
        this.roomType = roomType;
    }

    public String getRoomNumber() {
        return roomNumber;
    }

    public void setRoomNumber(String roomNumber) {
        this.roomNumber = roomNumber;
    }

    public Integer getFloor() {
        return floor;
    }

    public void setFloor(Integer floor) {
        this.floor = floor;
    }

    public RoomStatus getStatus() {
        return status;
    }

    public void setStatus(RoomStatus status) {
        this.status = status;
        this.lastStatusAt = Instant.now();
    }

    public Instant getLastStatusAt() {
        return lastStatusAt;
    }

    public void setLastStatusAt(Instant lastStatusAt) {
        this.lastStatusAt = lastStatusAt;
    }

    public Set<RoomStatusHistory> getStatusHistory() {
        return statusHistory;
    }

    public void setStatusHistory(Set<RoomStatusHistory> statusHistory) {
        this.statusHistory = statusHistory;
    }

    @Override
    public int hashCode() {
        int hash = 0;
        hash += (id != null ? id.hashCode() : 0);
        return hash;
    }

    @Override
    public boolean equals(Object object) {
        if (!(object instanceof Room)) {
            return false;
        }
        Room other = (Room) object;
        return (this.id != null || other.id == null) && (this.id == null || this.id.equals(other.id));
    }

    @Override
    public String toString() {
        return "Room[id=" + id + ", roomNumber=" + roomNumber + "]";
    }
}