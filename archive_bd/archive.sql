create table rack (
	id int primary key
);

create table shelf (
	id int primary key,
	rack_id int references rack on delete restrict
);

create table cell (
	id int primary key,
	shelf_id int references shelf on delete restrict,
	is_empty bool default true not null
);

create table theme (
	id serial primary key,
	name varchar(96) not null
);

create table documents (
	id serial primary key,
	name varchar(96) not null,
	cell_id int references cell on delete restrict,
	theme_id int references theme on delete restrict,
	amount int check (amount > 0),
	receipt_date date
);

create table department (
	id serial primary key,
	name varchar(96) not null,
	phone varchar(12) not null
);

create table employee (
	id serial primary key,
	name varchar (96) not null,
	department_id int references department on delete restrict
);

create table requests (
	id serial primary key,
	request_date date,
	document_id int references documents on delete restrict,
	employee_id int references employee on delete restrict
);

select * from add_document('График отпусков', 'Отпуск', 5);

select * from documents;

select * from theme;

select * from cell;

select * from shelf;

select * from rack;

insert into rack values (1);
insert into shelf values (1, 1);
insert into cell values 
(1, 1, true);
insert into theme (name) values ('Покупки'), ('Продажи');
insert into documents (name, cell_id, theme_id, amount, receipt_date) values
('Покупка оборудования', 2, 1, 5, '20.10.2023'),
('Продажа товара', 7, 2, 3, '15.01.2020');

insert into requests (request_date, document_id, employee_id) values
('23.11.2023', 1, 1),
('25.11.2023', 1, 2),
('27.11.2023', 1, 3),
('26.11.2023', 2, 1),
('27.11.2023', 2, 4);

select * from documents;

insert into requests (request_date, document_id, employee_id) values
('01.01.1001', 8, 3);

insert into department (name, phone) values
('Бухгалтерия', '+79088888888'),
('Отдел кадров', '+79500000000');

insert into employee (name, department_id) values
('Иванов И.И.', 1),
('Петров П.П.', 2),
('Андреев А.А.', 1),
('Романов Р.Р.', 2);

drop table requests;
drop table employee;
drop table department;
drop table documents;
drop table theme;
drop table cell;
drop table shelf;
drop table rack;

create user archive_admin superuser password 'Jsp4j4JcKQXl';
create user employee;
grant execute on function get_theme_by_document_name to employee;
grant execute on function get_document_name_with_max_amount to employee;
grant execute on function get_document_name_with_max_requests to employee;
grant execute on function get_document_amount_by_theme to employee;
grant execute on function get_last_employee to employee;
grant execute on function get_department_of_employee_with_max_requests to employee;
grant execute on function report_employee_by_department to employee;
grant execute on function report_archive_summary to employee;
