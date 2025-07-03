package com.mycompany.hotels.entity;

import java.io.Serializable;
import java.time.Instant;
import javax.persistence.*;

@Entity
@Table(name = "room_status_history")
public class RoomStatusHistory implements Serializable {
    private static final long serialVersionUID = 1L;
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(name = "previous_status")
    @Enumerated(EnumType.STRING)
    private RoomStatus previousStatus;

    @Column(name = "new_status", nullable = false)
    @Enumerated(EnumType.STRING)
    private RoomStatus newStatus;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "changed_by", nullable = false)
    private User changedBy;

    @Column(name = "changed_at", nullable = false)
    private Instant changedAt;
    
    public RoomStatusHistory() {
        this.changedAt = Instant.now();
    }
    
    public RoomStatusHistory(Room room, RoomStatus previousStatus, RoomStatus newStatus, User changedBy) {
        this();
        this.room = room;
        this.previousStatus = previousStatus;
        this.newStatus = newStatus;
        this.changedBy = changedBy;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Room getRoom() {
        return room;
    }

    public void setRoom(Room room) {
        this.room = room;
    }

    public RoomStatus getPreviousStatus() {
        return previousStatus;
    }

    public void setPreviousStatus(RoomStatus previousStatus) {
        this.previousStatus = previousStatus;
    }

    public RoomStatus getNewStatus() {
        return newStatus;
    }

    public void setNewStatus(RoomStatus newStatus) {
        this.newStatus = newStatus;
    }

    public User getChangedBy() {
        return changedBy;
    }

    public void setChangedBy(User changedBy) {
        this.changedBy = changedBy;
    }

    public Instant getChangedAt() {
        return changedAt;
    }

    public void setChangedAt(Instant changedAt) {
        this.changedAt = changedAt;
    }

    @Override
    public int hashCode() {
        int hash = 0;
        hash += (id != null ? id.hashCode() : 0);
        return hash;
    }

    @Override
    public boolean equals(Object object) {
        if (!(object instanceof RoomStatusHistory)) {
            return false;
        }
        RoomStatusHistory other = (RoomStatusHistory) object;
        return (this.id != null || other.id == null) && (this.id == null || this.id.equals(other.id));
    }

    @Override
    public String toString() {
        return "RoomStatusHistory[id=" + id + "]";
    }
}