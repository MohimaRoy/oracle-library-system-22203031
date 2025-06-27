# oracle-library-system-22203031


University Library Management System: Project Documentation
This document serves as the comprehensive overview for a university library management system, developed as the final project for a Database Systems course. It encapsulates the core principles of database design, implementation, and administration using SQL and PL/SQL.

Project Vision & Achievements
This assignment was designed to showcase my proficiency in various database concepts, from foundational design to advanced programming and administration.

Core Objectives Achieved:
System Design: Successfully designed and implemented a robust database schema for a functional library system.

Relational Mastery: Applied normalization and relational database theory to ensure data integrity and efficiency.

Advanced Querying: Developed sophisticated SQL queries for data retrieval, manipulation, and analytical reporting.

Procedural Logic: Implemented PL/SQL procedures, functions, and triggers to automate critical library operations.

Operational Excellence: Demonstrated skills in database security, user management, and performance tuning.

Assignment Breakdown & Deliverables
The project was structured into five distinct parts, each addressing a critical aspect of database development.

Part 1: Foundational Setup (15 Marks)

✅ Schema Definition: Created all necessary tables (BOOKS, MEMBERS, TRANSACTIONS) with appropriate constraints.

✅ Data Population: Inserted initial datasets, including 20 books, 15 members, and 25 transactions, to simulate real-world scenarios.

Part 2: Essential SQL Operations (20 Marks)

✅ Data Insights: Developed queries to identify available books (those with copies lent out), members with overdue items, the top 5 most borrowed books, and members with a history of late returns.

✅ Data Management: Implemented data manipulation scripts for updating overdue fines, securely adding new members (preventing duplicates), and archiving historical transaction data.

Part 3: Sophisticated Querying (25 Marks)

✅ Inter-Table Queries: Utilized various JOIN types (INNER, LEFT, SELF, CROSS) for comprehensive data linking and reporting.

✅ Nested Queries: Employed subqueries to answer complex questions, such as identifying books borrowed above the average rate or members with higher-than-average fines for their membership type.

✅ Analytical Functions: Applied aggregate and window functions (SUM, COUNT, AVG, RANK, LAG) for running totals, intra-group rankings, and trend analysis.

Part 4: Automated Business Logic (25 Marks)

✅ Book Issuing Automation: Created an ISSUE_BOOK stored procedure for streamlined book lending with built-in validation and error handling.

✅ Fine Calculation Engine: Developed a CALCULATE_FINE function to precisely determine overdue charges.

✅ Inventory Synchronization: Implemented an UPDATE_AVAILABLE_COPIES trigger to automatically adjust book availability upon return.

Part 5: Database Governance (15 Marks)

✅ Access Control: Established distinct user roles (librarian, student_user) with defined privileges.

✅ Performance Enhancement: Applied indexing strategies and analyzed execution plans to optimize query performance.

Technology Stack
The project was primarily developed using Oracle Database, leveraging its powerful SQL and PL/SQL capabilities.

Component

Technology

Database System

Oracle Database

Query Language

SQL (DML, DDL, DCL, TCL)

Procedural Language

PL/SQL

Management Tools

Oracle Database Tools

Core System Capabilities
The developed system boasts a range of features designed for efficient library management:

1. Robust Data Management
📚 Book Inventory:
Detailed tracking of book attributes (title, author, publisher, ISBN).

Categorization and real-time inventory counts (total vs. available copies).

👥 Member Directory:
Comprehensive member profiles, including contact information.

Support for different membership types (students, faculty, staff).

📝 Transaction Records:
Logging of all borrowing and return operations.

Automated tracking of issue, due, and return dates, along with fine status.

2. Sophisticated Data Analysis
Retrieval for Operations & Reporting:
Instant visibility into current book availability.

Identification of overdue items and their respective members.

Insights into popular books via borrowing frequency.

Detailed member activity reports.

Dynamic Data Modification:
Automatic calculation and update of overdue fines.

Secure and validated new member registration.

Archiving of older, completed transaction data to maintain performance.

Data Relationship Exploration:
INNER JOIN: For combined data from active transactions involving members and books.

LEFT JOIN: To list all books, even those without a borrowing history.

SELF JOIN: Useful for identifying members with shared borrowing interests (e.g., same categories).

CROSS JOIN: For generating all possible member-book pairings, aiding in recommendation system development.

Targeted Data Selection (Subqueries):
Identifying top-performing items or members based on specific metrics.

Analyzing usage patterns and identifying outliers (ee.g., high-fine users, least borrowed books).

Trend & Statistical Analysis (Aggregate & Window Functions):
Aggregate Functions: SUM, COUNT, AVG for overall statistics.

Window Functions: RANK(), LAG() for analyzing trends over time and ranking within groups.

3. Automated Processes with PL/SQL
📚 ISSUE_BOOK Procedure:
Streamlined book lending with checks for book availability.

Automatic generation of new transaction records.

Real-time decrement of available book copies.

Robust error handling for seamless operations.

💰 CALCULATE_FINE Function:
Precise calculation of fines based on overdue days.

Accepts a transaction ID and applies a daily rate (₹5).

🔄 UPDATE_AVAILABLE_COPIES Trigger:
Automatically updates the book inventory when a book's status changes to 'Returned'.

Ensures consistent and accurate stock counts.

4. Database Administration & Optimization
🔐 Security & Access Control:
Implemented Role-Based Access Control (RBAC).

librarian role: Granted full administrative privileges across the system.

student_user role: Limited to read-only access on the BOOKS table for inquiries.

Comprehensive privilege management to enforce security policies.

⚡ Performance Enhancement:
Strategic creation of indexes on frequently queried columns.

Analysis of query execution plans to identify and resolve performance bottlenecks.

Recommendations for further database monitoring and optimization.

Project Structure
The project files are organized for clarity and ease of execution.

oracle-library-system-[student-id]/
│
├── README.md               → This project documentation
│
└── sql/
    ├── setup.sql           → Database creation, table definitions, and sample data
    ├── queries.sql         → All basic and advanced SQL queries
    ├── plsql.sql           → Stored procedures, functions, and triggers
    └── admin.sql           → User management and performance optimization scripts

File Contents:
setup.sql: Contains Data Definition Language (DDL) statements for creating the database schema, including primary and foreign key relationships, along with initial data insertion.

queries.sql: Houses all SQL queries required by the assignment, categorized and extensively commented for understanding their purpose and expected output.

plsql.sql: Includes the complete PL/SQL code for procedures, functions, and triggers, detailing their parameters, return values, and operational logic.

admin.sql: Scripts for user role creation, privilege assignments, index creation, and other database administration commands.

Getting Started
To set up and run the system:

Establish Database Connection:
Connect to your Oracle Database instance using SQL*Plus or a similar client:

sqlplus username/password@database

Execute Scripts in Sequence:
Run the SQL files in the following order to ensure proper setup:

@sql/setup.sql    -- Initializes tables and populates data
@sql/queries.sql  -- Executes all predefined queries
@sql/plsql.sql    -- Deploys procedures, functions, and triggers
@sql/admin.sql    -- Configures user roles and performance indexes

Database Schema Overview
The system comprises three primary tables:

BOOKS: Manages the library's inventory, storing details like book_id, title, author, publisher, publication_year, isbn, category, total_copies, available_copies, and price.

MEMBERS: Contains information about library users, including member_id, first_name, last_name, email, phone, address, membership_date, and membership_type.

TRANSACTIONS: Records lending and return activities with transaction_id, member_id, book_id, issue_date, due_date, return_date, fine_amount, and status.

Assignment Implementation Highlights
The system directly addresses all assignment requirements:

Data Fidelity:
Populated with 20 diverse books.

Includes 15 members representing various types.

Features 25 transactions covering returned, pending, and overdue states.

Key Functional Queries:
Identifies books with available copies less than total.

Lists all members with overdue books.

Highlights the top 5 most borrowed books.

Pinpoints members who have a history of late returns.

Calculates fines at a rate of ₹5 per day for overdue returns.

Automated Logic:
The ISSUE_BOOK procedure handles the complete process of lending a book.

The CALCULATE_FINE function provides precise fine computation.

A trigger automatically updates book counts upon return.

User Privileges:
A librarian user with full system access.

A student_user with restricted SELECT access to BOOKS table only.
