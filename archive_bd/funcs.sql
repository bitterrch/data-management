create function get_theme_by_document_name(
	documents_name_ varchar(96)
	) returns table(theme varchar) language plpgsql as $$
	begin
		return query
			select theme.name from documents
			join theme on theme.id = documents.theme_id
			where documents.name = documents_name_;
	end
$$;

create function get_document_name_with_max_amount()
	returns table(documents varchar) language plpgsql as $$
	begin
		return query
			select documents.name from documents
			where amount = (select max(amount) from documents);
	end	
$$;

create function get_document_name_with_max_requests()
	returns table(documents varchar) language plpgsql as $$
	begin
		return query
			select documents.name 
			from documents inner join requests
			on documents.id = requests.document_id
			group by documents.id 
			having count(document_id) = (select max(Счёт) from (
				select count(document_id) as Счёт from requests
				group by document_id));
	end
$$;

create function get_document_amount_by_theme(
	theme_name_ varchar(96)
	) returns table(amount bigint) language plpgsql as $$
	begin
		return query
			select count(documents.amount)
			from documents inner join theme
			on documents.theme_id = theme.id
			where theme.name = theme_name_
			group by documents.theme_id;
	end
$$;

create function get_last_employee(
	document_name_ varchar(96)
)returns table(employee varchar(96), requests date) language plpgsql as $$
	begin
		return query
			select employee.name, request_date from requests
			inner join employee 
			on employee_id = employee.id
			inner join documents
			on documents.id = document_id
			where documents.name = document_name_
			and request_date = (select max(request_date) from requests
						inner join documents
						on documents.id = document_id
						where documents.name = document_name_);
	end
$$;

create function get_department_of_employee_with_max_requests()
	returns table(department varchar(96)) language plpgsql as $$
	begin
		return query
				select department.name
				from department
				where department.id = (select employee.department_id
							from employee inner join requests
							on employee.id = employee_id
							group by employee.id
							having count(employee_id) = (select max(Счёт) from 
								(select count(employee_id) as Счёт from requests
								group by employee_id)));
	end
$$;

create function add_document(
		document_name_ varchar(96),
		theme_name_ varchar(96),
		amount_ int	
) returns void language plpgsql as $$
	declare
		theme_id_ int;
		cell_id_ int;
		shelf_id_ int;
		rack_id_ int;
	begin
		select id from theme where name = theme_name_ into theme_id_;
		if theme_id_ is null then
			insert into theme (name) values (theme_name_) returning id into theme_id_;
		end if;
		
		select id from cell where is_empty = true limit 1 into cell_id_;
		if cell_id_ is null then
			select max(id)+1 from cell into cell_id_; 
			select id from shelf where id = (cell_id_+1)/2 into shelf_id_;
			if shelf_id_ is null then
				select max(id)+1 from shelf into shelf_id_;
				select id from rack where id = (shelf_id_+1)/2 into rack_id_;
				if rack_id_ is null then
					select max(id)+1 from rack into rack_id_;
					if rack_id_ is null then
						set rack_id_ = 1;
						set shelf_id_ = 1;
						set cell_id_ = 1;
					end if;
					insert into rack values (rack_id_);
				end if;
				insert into shelf values (shelf_id_, rack_id_);
			end if;
			insert into cell values (cell_id_, shelf_id_, false);
		end if;
	
		update cell 
		set is_empty = false
		where id = cell_id_;
		
		insert into documents (name, cell_id, theme_id, amount, receipt_date)
		values (document_name_, cell_id_, theme_id_, amount_, current_date);
	end
$$;

drop function add_document;

create function delete_document_copy(
		document_name_ varchar(96),
		copy_amount_ int
) returns void language plpgsql as $$
	declare
		amount_ int;
		id_ int;
		
	begin
		select amount-copy_amount_ from documents where name = document_name_ into amount_;
		if amount_ > 0 then
			update documents 
			set amount = amount_
			where name = document_name_;
		end if;
	
		if amount_ <= 0 then
			select cell_id from documents where name = document_name_ into id_;
			delete from documents where name = document_name_;
			update cell
			set is_empty = true
			where id = id_;
		end if;
	end
$$;

create function change_phone_number(
	department_ varchar(96), phone_ varchar(15)
) returns void language plpgsql as $$
	begin
		update department
		set phone = phone_
		where name = department_;
	end	
$$;

create function report_employee_by_department(
	department_ varchar(96)
)
returns table (employee varchar(96), document varchar(96), request date) language plpgsql as $$
	begin
		return query
			select employee.name, documents.name, request_date
			from requests 
			inner join employee
			on employee_id = employee.id
			inner join documents
			on document_id = documents.id
			inner join department
			on department_id = department.id
			where department.name = department_;
	end
$$;

create function report_archive_summary()
returns void language plpgsql as $$
	declare
		i record;
	begin
		raise notice 'Document Count: %', (select count(*) from documents);
		raise notice ' ';
		raise notice 'Copy Count: %', (select sum(amount) from documents);
		raise notice ' ';
		raise notice 'Documents Added For The Last Month: ';
		for i in select name from documents 
		where receipt_date in (current_date - 31, current_date) loop
			raise notice '- %', i.name;
		end loop;
		raise notice ' ';
		raise notice 'All Documents Information: ';
		for i in select name, amount, cell_id, shelf_id, rack_id from documents
		inner join cell
		on cell_id = cell.id
		inner join shelf
		on shelf_id = shelf.id loop 
			raise notice '- %', i.name;
			raise notice '--- Amount: %', i.amount;
			raise notice '--- Cell: %', i.cell_id;
			raise notice '--- Shelf: %', i.shelf_id;
			raise notice '--- Rack: %', i.rack_id;
		end loop;
		
	end
$$;
