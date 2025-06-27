-- SQL Code for Database Query Optimization and Library Management System Operations

-- 1. Create Indexes on Frequently Queried Columns
-- These statements create non-clustered indexes on specific columns.
-- An index helps the database system to locate data more quickly,
-- similar to how an index in a book helps you find information.

-- Create an index on the 'author' column in the 'BOOKS' table.
-- This will speed up queries that filter or sort by author.
CREATE INDEX idx_books_author ON BOOKS(author);

-- Create an index on the 'title' column in the 'BOOKS' table.
-- This will enhance performance for queries that search or sort by title.
CREATE INDEX idx_books_title ON BOOKS(title);

-- Create an index on the 'member_id' column in the 'TRANSACTIONS' table.
-- This is useful for quickly retrieving transactions associated with a specific member.
CREATE INDEX idx_transactions_member ON TRANSACTIONS(member_id);

-- Create an index on the 'book_id' column in the 'TRANSACTIONS' table.
-- This will improve the speed of queries that involve looking up transactions
-- for a particular book.
CREATE INDEX idx_transactions_book ON TRANSACTIONS(book_id);


-- 2. Write a Query to Show Execution Plan for Finding Books by Author
-- The EXPLAIN (or EXPLAIN PLAN depending on the database system) statement
-- shows the execution plan of a SQL statement. It describes how the database
-- will execute the query, including which indexes it will use, if any,
-- and the order of operations.

-- Show the execution plan for a SELECT query that finds all books by 'John Smith'.
-- This will tell you if the 'idx_books_author' index is being utilized.
EXPLAIN SELECT * FROM BOOKS WHERE author = 'John Smith';


-- 3. Display Member Borrowing Trends with LAG Function
-- This query uses the LAG window function to retrieve the issue_date of the
-- previous transaction for each member, ordered by their transaction history.
-- This helps in analyzing borrowing patterns and trends for individual members.

SELECT
    member_id,
    transaction_id,
    issue_date,
    LAG(issue_date) OVER (PARTITION BY member_id ORDER BY issue_date) AS previous_transaction_date
FROM TRANSACTIONS
ORDER BY member_id, issue_date;


-- 4. Library Management Stored Procedures, Functions, and Triggers

-- 4.1 Stored Procedure: ISSUE_BOOK
-- This stored procedure handles the process of issuing a book to a member.
-- It includes checks for book availability, generates a new transaction ID,
-- inserts a new record into the TRANSACTIONS table, and updates the
-- available copies in the BOOKS table. It uses transactions for data integrity.

DELIMITER $$

CREATE PROCEDURE ISSUE_BOOK (
    IN p_member_id INT,
    IN p_book_id INT
)
proc_label: BEGIN
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_max_transaction_id INT DEFAULT 0;

    -- Define an exit handler for SQL exceptions to rollback the transaction
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error: Could not issue book.' AS message;
    END;

    -- Start a transaction to ensure atomicity of operations
    START TRANSACTION;

    -- Check book availability and lock the row for update to prevent race conditions
    SELECT available_copies INTO v_available
    FROM BOOKS
    WHERE book_id = p_book_id
    FOR UPDATE;

    -- Handle cases where the book does not exist
    IF v_available IS NULL THEN
        ROLLBACK;
        SELECT 'Error: Book does not exist.' AS message;
        LEAVE proc_label; -- Exit the procedure
    END IF;

    -- Handle cases where the book is not available for issuing
    IF v_available <= 0 THEN
        ROLLBACK;
        SELECT 'Error: Book not available for issuing.' AS message;
        LEAVE proc_label; -- Exit the procedure
    END IF;

    -- Get the maximum transaction_id to generate a new unique ID
    SELECT IFNULL(MAX(transaction_id), 0) INTO v_max_transaction_id FROM TRANSACTIONS;

    -- Insert a new transaction record into the TRANSACTIONS table
    INSERT INTO TRANSACTIONS (
        transaction_id, member_id, book_id, issue_date, due_date, return_date, fine_amount, status
    ) VALUES (
        v_max_transaction_id + 1,        -- New transaction ID
        p_member_id,                     -- Member ID
        p_book_id,                       -- Book ID
        CURDATE(),                       -- Current issue date
        DATE_ADD(CURDATE(), INTERVAL 14 DAY), -- Due date (14 days from issue)
        NULL,                            -- Return date is initially NULL
        0.00,                            -- Initial fine amount
        'Pending'                        -- Transaction status
    );

    -- Update the number of available copies for the issued book
    UPDATE BOOKS
    SET available_copies = available_copies - 1
    WHERE book_id = p_book_id;

    -- Commit the transaction if all operations are successful
    COMMIT;

    -- Return a success message with the new transaction ID
    SELECT CONCAT('Book issued successfully. Transaction ID: ', v_max_transaction_id + 1) AS message;

END proc_label $$

DELIMITER ;


-- 4.2 Stored Function: CALCULATE_FINE
-- This function calculates the fine for a given transaction.
-- It determines the overdue days based on the due date and return date (or current date if not returned).
-- A fine of ₹5 per day is applied for overdue books.

DELIMITER $$

CREATE FUNCTION CALCULATE_FINE(p_transaction_id INT)
RETURNS DECIMAL(6,2)
DETERMINISTIC
BEGIN
    DECLARE v_due_date DATE;
    DECLARE v_return_date DATE;
    DECLARE v_today DATE;
    DECLARE v_overdue_days INT DEFAULT 0;
    DECLARE v_fine DECIMAL(6,2) DEFAULT 0.00;

    SET v_today = CURDATE(); -- Get the current date

    -- Retrieve the due_date and return_date for the specified transaction
    SELECT due_date, return_date
    INTO v_due_date, v_return_date
    FROM TRANSACTIONS
    WHERE transaction_id = p_transaction_id;

    -- Calculate overdue days:
    -- If the book has been returned, calculate days between return_date and due_date.
    -- Otherwise, calculate days between today's date and the due_date.
    IF v_return_date IS NOT NULL THEN
        SET v_overdue_days = DATEDIFF(v_return_date, v_due_date);
    ELSE
        SET v_overdue_days = DATEDIFF(v_today, v_due_date);
    END IF;

    -- If there are overdue days, calculate the fine (₹5 per day)
    IF v_overdue_days > 0 THEN
        SET v_fine = v_overdue_days * 5;
    ELSE
        SET v_fine = 0.00; -- No fine if not overdue
    END IF;

    RETURN v_fine; -- Return the calculated fine
END $$

DELIMITER ;

-- Example of how to call the CALCULATE_FINE function
SELECT CALCULATE_FINE(1) AS fine_for_transaction_1;


-- 4.3 Trigger: update_available_copies_after_return
-- This trigger automatically updates the 'available_copies' in the BOOKS table
-- when a transaction's status changes to 'Returned'. This ensures that the
-- book count is accurate as books are returned to the library.

DELIMITER $$

CREATE TRIGGER update_available_copies_after_return
AFTER UPDATE ON TRANSACTIONS
FOR EACH ROW
BEGIN
    -- Check if the 'status' column has changed from something else to 'Returned'
    IF OLD.status <> 'Returned' AND NEW.status = 'Returned' THEN
        -- Increment the available_copies for the book associated with the returned transaction
        UPDATE BOOKS
        SET available_copies = available_copies + 1
        WHERE book_id = NEW.book_id;
    END IF;
END $$

DELIMITER ;


-- 5. User Management and Privileges

-- 5.1 Create Users
-- These statements create two new database users: 'librarian' and 'student_user',
-- each with a specified password.

CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'lib_password123';
CREATE USER 'student_user'@'localhost' IDENTIFIED BY 'student_password123';


-- 5.2 Grant Privileges
-- These statements define the access rights for the newly created users.
-- The 'librarian' gets full access to the 'Library_Management_System' database,
-- while the 'student_user' is granted read-only access (SELECT) to the 'BOOKS' table.

-- Grant all privileges on the 'Library_Management_System' database to the 'librarian'.
GRANT ALL PRIVILEGES ON Library_Management_System.* TO 'librarian'@'localhost';

-- Grant SELECT (read) privilege only on the 'BOOKS' table
-- within the 'Library_Management_System' database to 'student_user'.
GRANT SELECT ON Library_Management_System.BOOKS TO 'student_user'@'localhost';

-- Apply the changes to the privilege tables to ensure they take effect immediately.
FLUSH PRIVILEGES;


-- Optional: Drop Users (for cleanup or re-creation)
-- These statements are commented out but can be used to remove the users if needed.
-- DROP USER 'librarian'@'localhost';
-- DROP USER 'student_user'@'localhost';

-- Re-creation of users and grants (if they were dropped)
-- This section ensures the users and their privileges are set up
-- if the DROP USER statements were executed previously.
-- CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'lib_password123';
-- CREATE USER 'student_user'@'localhost' IDENTIFIED BY 'student_password123';
-- GRANT ALL PRIVILEGES ON Library_Management_System.* TO 'librarian'@'localhost';
-- GRANT SELECT ON Library_Management_System.BOOKS TO 'student_user'@'localhost';
-- FLUSH PRIVILEGES;
