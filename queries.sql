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

-- 6. Additional Library Management Queries and Data Manipulation

-- 6.1 Task 2.1: Advanced Queries

-- 1. List all books with their available copies where available copies are less than total copies
-- This query identifies books that have been borrowed at least once, showing their current stock status.
SELECT book_id, title, total_copies, available_copies
FROM BOOKS
WHERE available_copies < total_copies;

-- 2. Find members who have overdue books
-- This query retrieves the details of members and their overdue books, based on the due date and transaction status.
SELECT M.member_id, M.first_name, M.last_name, T.book_id, T.due_date
FROM MEMBERS M
JOIN TRANSACTIONS T ON M.member_id = T.member_id
WHERE T.due_date < CURDATE() AND T.status = 'Overdue';

-- 3. Display the top 5 most borrowed books with their borrow count
-- This query counts the number of times each book has been borrowed and lists the top 5.
SELECT B.book_id, B.title, COUNT(T.transaction_id) AS borrow_count
FROM BOOKS B
JOIN TRANSACTIONS T ON B.book_id = T.book_id
GROUP BY B.book_id, B.title
ORDER BY borrow_count DESC
LIMIT 5;

-- 4. Show members who have never returned a book on time
-- This query identifies members who have a history of returning books past their due date.
SELECT DISTINCT M.member_id, M.first_name, M.last_name
FROM MEMBERS M
JOIN TRANSACTIONS T ON M.member_id = T.member_id
WHERE T.return_date IS NOT NULL AND T.return_date > T.due_date; -- Added IS NOT NULL for return_date


-- 6.2 Task 2.2: Data Manipulation

-- 1. Update fine amounts for all overdue transactions (₹5 per day after due date)
-- This updates the fine_amount for transactions where the book was returned late.
SET SQL_SAFE_UPDATES = 0; -- Temporarily disable safe updates for bulk operations

UPDATE TRANSACTIONS
SET fine_amount = DATEDIFF(return_date, due_date) * 5
WHERE return_date IS NOT NULL AND return_date > due_date; -- Ensure return_date is not NULL

SET SQL_SAFE_UPDATES = 1; -- Re-enable safe updates

-- 2. Insert a new member with membership validation (no duplicate email or phone)
-- This statement inserts a new member only if their email or phone number does not already exist in the MEMBERS table.
INSERT INTO MEMBERS (member_id, first_name, last_name, email, phone, address, membership_date, membership_type)
SELECT 16, 'Rafi', 'Hasan', 'rafi@example.com', '01234567906', 'Narsingdi, BD', CURDATE(), 'Student'
WHERE NOT EXISTS (
    SELECT 1 FROM MEMBERS WHERE email = 'rafi@example.com' OR phone = '01234567906'
);

-- 3. Archive completed transactions older than 2 years to a separate table
-- This task involves creating an archive table and then moving old, completed transaction data to it.

-- Step 1: Create archive table
-- This creates a new table with the same structure as TRANSACTIONS, but no data.
CREATE TABLE IF NOT EXISTS TRANSACTION_ARCHIVE AS
SELECT * FROM TRANSACTIONS WHERE 1 = 0;

-- Step 2: Insert into archive and delete from main table
-- Insert old returned transactions into the archive table.
INSERT INTO TRANSACTION_ARCHIVE
SELECT * FROM TRANSACTIONS
WHERE status = 'Returned' AND return_date < CURDATE() - INTERVAL 2 YEAR;

-- Delete them from the main TRANSACTIONS table.
DELETE FROM TRANSACTIONS
WHERE status = 'Returned' AND return_date < CURDATE() - INTERVAL 2 YEAR;

-- 4. Update book categories based on publication year ranges
-- This query assigns categories ('Classic', 'Standard', 'Modern') to books based on their publication year.
UPDATE BOOKS
SET category = CASE
    WHEN publication_year < 2000 THEN 'Classic'
    WHEN publication_year BETWEEN 2000 AND 2010 THEN 'Standard'
    ELSE 'Modern'
END;


-- 6.3 Task 3.1: Joins

-- 1. Display transaction history with member details and book information for all overdue books using INNER JOIN
-- This query combines data from TRANSACTIONS, MEMBERS, and BOOKS tables to show details of overdue transactions.
SELECT
    T.transaction_id,
    M.member_id, M.first_name, M.last_name,
    B.book_id, B.title, B.category,
    T.issue_date, T.due_date, T.return_date, T.status
FROM TRANSACTIONS T
INNER JOIN MEMBERS M ON T.member_id = M.member_id
INNER JOIN BOOKS B ON T.book_id = B.book_id
WHERE T.status = 'Overdue';

-- 2. Show all books and their transaction count (including books never borrowed) using LEFT JOIN
-- This query lists every book and the number of times it has been borrowed.
-- Books that have never been borrowed will show a count of 0.
SELECT
    B.book_id, B.title, COUNT(T.transaction_id) AS transaction_count
FROM BOOKS B
LEFT JOIN TRANSACTIONS T ON B.book_id = T.book_id
GROUP BY B.book_id, B.title
ORDER BY transaction_count DESC;

-- 3. Find members who have borrowed books from the same category as other members using SELF JOIN
-- This complex query identifies pairs of members who have borrowed books belonging to the same category.
SELECT DISTINCT
    M1.member_id AS member1_id, M1.first_name AS member1_name,
    M2.member_id AS member2_id, M2.first_name AS member2_name,
    B1.category
FROM TRANSACTIONS T1
JOIN MEMBERS M1 ON T1.member_id = M1.member_id
JOIN BOOKS B1 ON T1.book_id = B1.book_id
JOIN TRANSACTIONS T2 ON B1.category = (SELECT B2.category FROM BOOKS B2 WHERE B2.book_id = T2.book_id)
JOIN MEMBERS M2 ON T2.member_id = M2.member_id
WHERE M1.member_id <> M2.member_id;

-- 4. List all possible member-book combinations for recommendation system using CROSS JOIN (limit to 50 results)
-- This generates every possible pairing of members and books, useful for recommendation engines.
SELECT
    M.member_id, M.first_name, M.last_name,
    B.book_id, B.title, B.category
FROM MEMBERS M
CROSS JOIN BOOKS B
LIMIT 50;


-- 6.4 Task 3.2: Subqueries and Derived Tables

-- 1. Find all books that have been borrowed more times than the average borrowing rate across all books
-- This query identifies books that are more popular than the overall average borrowing frequency.
SELECT book_id, title
FROM BOOKS
WHERE book_id IN (
    SELECT book_id
    FROM TRANSACTIONS
    GROUP BY book_id
    HAVING COUNT(*) > (
        SELECT AVG(borrow_count)
        FROM (
            SELECT COUNT(*) AS borrow_count
            FROM TRANSACTIONS
            GROUP BY book_id
        ) AS borrow_stats
    )
);

-- 2. List members whose total fine amount is greater than the average fine paid by their membership type
-- This query compares each member's total fines against the average fines for their specific membership type.
SELECT member_id, first_name, last_name, total_fine
FROM (
    SELECT M.member_id, M.first_name, M.last_name, M.membership_type,
           SUM(T.fine_amount) AS total_fine
    FROM MEMBERS M
    JOIN TRANSACTIONS T ON M.member_id = T.member_id
    GROUP BY M.member_id, M.first_name, M.last_name, M.membership_type
) AS member_fines
WHERE total_fine > (
    SELECT AVG(total_fine)
    FROM (
        SELECT M.member_id, M.membership_type, SUM(T.fine_amount) AS total_fine
        FROM MEMBERS M
        JOIN TRANSACTIONS T ON M.member_id = T.member_id
        GROUP BY M.member_id, M.membership_type
    ) AS type_fines
    WHERE type_fines.membership_type = member_fines.membership_type
);

-- 3. Display books that are currently available but belong to the same category as the most borrowed book
-- This query finds available books in the category that has the highest borrowing activity.
SELECT book_id, title, category
FROM BOOKS
WHERE available_copies > 0
AND category = (
    SELECT B.category
    FROM BOOKS B
    JOIN TRANSACTIONS T ON B.book_id = T.book_id
    GROUP BY B.category
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

-- 4. Find the second most active member (by transaction count)
-- This query identifies the member with the second highest number of transactions.
SELECT member_id, first_name, last_name, txn_count
FROM (
    SELECT M.member_id, M.first_name, M.last_name, COUNT(T.transaction_id) AS txn_count
    FROM MEMBERS M
    JOIN TRANSACTIONS T ON M.member_id = T.member_id
    GROUP BY M.member_id, M.first_name, M.last_name
) AS member_txns
WHERE txn_count = (
    -- Find the second highest transaction count
    SELECT MAX(txn_count_ranked) FROM (
        SELECT COUNT(transaction_id) AS txn_count_ranked,
               DENSE_RANK() OVER (ORDER BY COUNT(transaction_id) DESC) as rnk
        FROM TRANSACTIONS
        GROUP BY member_id
    ) AS ranked_txns
    WHERE rnk = 2
);


-- 6.5 Task 3.3: Aggregate & Window Functions

-- 1. Calculate running total of fines collected by month using window functions
-- This query shows the cumulative sum of fines collected over time, grouped by month.
SELECT
    DATE_FORMAT(return_date, '%Y-%m') AS month,
    SUM(fine_amount) AS monthly_fine,
    SUM(SUM(fine_amount)) OVER (ORDER BY DATE_FORMAT(return_date, '%Y-%m')) AS running_total
FROM TRANSACTIONS
WHERE fine_amount > 0 AND return_date IS NOT NULL -- Added IS NOT NULL for return_date
GROUP BY month
ORDER BY month;

-- 2. Rank members by their borrowing activity within each membership type
-- This query assigns a rank to members based on their borrowing count, separately for each membership type.
SELECT
    member_id, first_name, last_name, membership_type, borrow_count,
    RANK() OVER (PARTITION BY membership_type ORDER BY borrow_count DESC) AS rank_within_type
FROM (
    SELECT M.member_id, M.first_name, M.last_name, M.membership_type, COUNT(T.transaction_id) AS borrow_count
    FROM MEMBERS M
    LEFT JOIN TRANSACTIONS T ON M.member_id = T.member_id
    GROUP BY M.member_id, M.first_name, M.last_name, M.membership_type
) AS sub;

-- 3. Find percentage contribution of each book category to total library transactions
-- This query calculates what percentage of all transactions each book category accounts for.
SELECT
    B.category,
    COUNT(T.transaction_id) AS category_transaction_count,
    ROUND(100 * COUNT(T.transaction_id) / (SELECT COUNT(*) FROM TRANSACTIONS), 2) AS percentage_contribution
FROM BOOKS B
LEFT JOIN TRANSACTIONS T ON B.book_id = T.book_id
GROUP BY B.category
ORDER BY percentage_contribution DESC;
