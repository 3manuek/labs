CREATE SUBSCRIPTION all_sub 
CONNECTION 'postgresql://postgres:postgres@postgres13:5432/testdb' 
PUBLICATION all_pub;