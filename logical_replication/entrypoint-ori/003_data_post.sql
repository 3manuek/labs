
create table testtable (i bigserial, sometxt text);

insert into testtable select i, random() from generate_series(1,1000) i(i);

insert into testtable select i, random() from generate_series(1,10000) i(i);

