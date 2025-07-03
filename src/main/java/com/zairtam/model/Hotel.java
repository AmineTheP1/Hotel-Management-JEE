package com.zairtam.model;

public class Hotel {
    private int id;
    private String name;
    private String location;
    private int managerId;
    
    public Hotel() {
    }
    
    public Hotel(String name, String location, int managerId) {
        this.name = name;
        this.location = location;
        this.managerId = managerId;
    }
    
    // Getters and Setters
    public int getId() {
        return id;
    }
    
    public void setId(int id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getLocation() {
        return location;
    }
    
    public void setLocation(String location) {
        this.location = location;
    }
    
    public int getManagerId() {
        return managerId;
    }
    
    public void setManagerId(int managerId) {
        this.managerId = managerId;
    }
}