-- SQL Code for Database Query Optimization

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
