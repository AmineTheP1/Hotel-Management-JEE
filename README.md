# Hotels JEE Project

This is a Java EE (JEE) multi-module project for hotel management, built using Maven. The project is organized into three main modules:

- **hotels-ear**: Enterprise Application Archive (EAR) module for deployment.
- **hotels-ejb**: Contains the business logic and entity beans (EJB module).
- **hotels-web**: Web application module (servlets, JSPs, etc.).

## Project Structure

```
hotels/
  hotels-ear/   # EAR packaging module
  hotels-ejb/   # EJB module (business logic, entities)
  hotels-web/   # Web module (servlets, JSP, static resources)
  src/          # (if present) shared or root-level code/resources
  pom.xml       # Parent Maven POM
```

## Prerequisites
- Java JDK 8 or higher
- Maven 3.x
- (Optional) GlassFish or any Java EE compatible application server
- MySQL (or compatible) database

## Build Instructions

To build the entire project, run from the root directory:

```
mvn clean install
```

This will build all modules and generate the EAR, WAR, and JAR files in their respective `target/` directories.

## Deployment

1. Deploy the generated `hotels-ear/target/hotels-ear-1.0-SNAPSHOT.ear` file to your Java EE application server (e.g., GlassFish).
2. Configure your database connection as specified in the `persistence.xml` and `glassfish-resources.xml` files.

## Database

- The project uses MySQL. See `room_tables.sql` for the database schema.
- Update database credentials in the configuration files as needed.

## Usage

- Access the web application via the application server's deployed URL (e.g., `http://localhost:8080/hotels-web/`).
- The web module contains JSPs for client, employee, and manager roles.

