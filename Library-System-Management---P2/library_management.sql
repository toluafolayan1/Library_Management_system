-- Library Mnagement project
select * from branch
select * from employees
select * from issued_status
select * from members
select * from return_status
select * from books


-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books(isbn, book_title, category, rental_price, status, author, publisher)
values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
select * from books

-- Task 2: Update an Existing Member's Address
update members
set member_address = '123 oke-afa st'
where member_address = '456 birch st'

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
delete from issued_status
where issued_id = 'IS106'

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
select issued_book_name
from issued_status
where issued_emp_id = 'E101'


-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
select
    members.member_name,
    count(*) as count_of_books_issued
from members
join issued_status on members.member_id = issued_status.issued_member_id
group by members.member_name
having count(*) > 1;


-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
create table book_counts
as
select 
	b.isbn,
	b.book_title,
	count(ist.issued_id) no_issued
from books b
join issued_status ist
on b.isbn = ist.issued_book_isbn
group by 1,2

select *
from book_counts

-- Task 7. Retrieve All Books in a Specific Category.
select *
from books
where category = 'Classic'

-- Task 8: Find Total Rental Income by Category:
select 
	b.category,
	sum(b.rental_price),
	count(*)
from books b
join issued_status ist
on b.isbn = ist.issued_book_isbn
group by 1


-- Task 9: List Members Who Registered in the Last 180 Days.
insert into members(member_id,member_name,member_address,reg_date)
values
	('C142','John smith','323 ijb st','2026-02-15'),
	('C143','Paul James','432 Oat st','2026-03-22')
	
select *
from members
--where (current_date - interval '180 days') <= reg_date  
 where reg_date >= current_date - interval '180 days'


-- Task 10: List Employees with Their Branch Manager's Name and their branch details
select 
	e.*,
	b.branch_id,
	e2.emp_name as manager
from employees e
join branch b
on e.branch_id = b.branch_id
join employees e2
on b.manager_id = e2.emp_id

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 7usd:
create table books_above_7USD
AS
select *
from books
where rental_price > 7

-- Task 12: Retrieve the List of Books Not Yet Returned
select 
	distinct ist.issued_book_name
from issued_status ist
left join return_status rs
on ist.issued_id = rs.issued_id
where rs.return_id is null


/* Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 35-day return period).
Display the member's_id, member's name, book title, issue date, and days overdue. */
select 
	ist.issued_member_id,
	m.member_name, 
	b.book_title, 
	ist.issued_date,
	--rs.return_date,
	current_date - ist.issued_date as overdue_days
from issued_status ist
join members m
on ist.issued_member_id = m.member_id
join books b
on b.isbn = ist.issued_book_isbn
left join return_status rs
on rs.issued_id = ist.issued_id
where
	rs.return_date is null
	and
	(current_date - ist.issued_date) > 35 
order by 1


/* Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned 
(based on entries in the return_status table). */

create or replace procedure add_return_records(p_return_id varchar (10),p_issued_id varchar(10),
p_book_quality varchar(50))
language plpgsql
as $$

declare
	v_isbn varchar(50);
	v_book_name varchar(50);
begin
	-- all your logic and code
	-- inserting into return based on users input
	insert into return_status(return_id,issued_id,return_date,book_quality)
	values (p_return_id,p_issued_id,CURRENT_DATE,p_book_quality);

	select
		issued_book_isbn,
		book_title
		into
		v_isbn,
		v_book_name
	from issued_status
	where issued_id = p_issued_id;

	update books
	set status = 'yes'
	where isbn = v_isbn;

	raise notice 'Thank you for returning the book : %', v_book_name;
	
end;
$$

call add_return_records('RS138', 'IS135', 'Good');

select * from return_status
where return_id = 'RS138';


/* Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number
of books issued, the number of books returned, and the total revenue generated from book rentals. */
create table branch_report
as 
select 
	br.branch_id,
	--br.manager_id,
	count(ist.issued_id) number_books_isued,
	count(rs.return_id)number_of_book_returned,
	sum(b.rental_price) total_revenue
from issued_status ist
join employees e
on e.emp_id = ist.issued_emp_id
join branch br
on e.branch_id = br.branch_id
left join return_status rs
on rs.issued_id = ist.issued_id
join books b
on ist.issued_book_isbn = b.isbn
group by 1

select *
from branch_report

/* Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members
containing members who have issued at least one book in the last  months. */
create table active_members
as
select *
from members
where member_id in (
    select distinct issued_member_id
    from issued_status
    where issued_date >= current_date - interval '2 months'
    group by 1
);

/* Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most 
book issues. Display the employee name, number of books processed, and their branch. */
select 
	b.branch_address,
	e.emp_name,
	count(*)no_of_books_processed
from employees e
join branch b on b.branch_id = e.branch_id
join issued_status ist on ist.issued_emp_id = e.emp_id
group by 1,2
order by 3 desc
limit 3


/* Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued 
books more than twice with the status "damaged" in the books table.
Display the member name, book title, and the number of times they've issued damaged books. */
select 
	m.member_name,
	ist.issued_book_name,
	count(ist.issued_id) count_of_issued_damaged_books
from members m
join issued_status ist on ist.issued_member_id = m.member_id
join return_status rs on rs.issued_id = ist.issued_id
where rs.book_quality = 'Damaged'
group by 1,2
having count(ist.issued_id) > 2


 /* Task 19: Create a stored procedure to manage the status of books in a library system.
Description: Write a stored procedure that updates the status of a book in the library
based on its issuance.
The procedure should function as follows: The stored procedure 
should take the book_id as an input parameter.
The procedure should first check if the book is available (status = 'yes'). If the book is 
available, it should be issued, and the status in the books table should be updated to 'no'.
If the book is not available (status = 'no'),
the procedure should return an error message indicating that the book is currently not available. */

create or replace procedure issue_book(p_issued_id varchar(10), p_issued_member_id varchar(30), p_issued_book_isbn varchar(30),
p_issued_emp_id varchar(10))
language plpgsql
as $$
declare
    v_status varchar(10);
begin
    select 
        status
        into v_status
    from books
    where isbn = p_issued_book_isbn;

    if v_status = 'yes' then
        insert into issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        values(p_issued_id, p_issued_member_id, current_date, p_issued_book_isbn, p_issued_emp_id);

        update books
        set status = 'no'
        where isbn = p_issued_book_isbn;

        raise notice 'Book records added successfully for book isbn : %', p_issued_book_isbn;
    else
        raise notice 'Sorry to inform you the book you have requested is unavailable book isbn : %', p_issued_book_isbn;
    end if;
end;
$$
call issue_book('IS141', 'C108', '978-0-7432-7357-1', 'E110');

/* Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query 
to identify overdue books and calculate fines. */																
create table overdue_books
as
select 
    ist.issued_id,
    ist.issued_member_id,
    ist.issued_book_name,
    ist.issued_date,
    rs.return_date,
    current_date - issued_date as days_overdue,
    case 
        when rs.return_date is null 
        and current_date - issued_date > 30 
        then (current_date - issued_date - 30) * 0.50
        else 0
    end as fine_amount
from issued_status ist
left join return_status rs on rs.issued_id = ist.issued_id
where rs.return_date is null 
and current_date - issued_date > 30;

select * from overdue_books

-- end of project

																
