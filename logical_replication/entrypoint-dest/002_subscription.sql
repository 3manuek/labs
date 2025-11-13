CREATE SUBSCRIPTION all_sub 
CONNECTION 'postgresql://postgres:postgres@postgres13:5432/testdb' 
PUBLICATION all_pub
WITH (enabled = true, 
      create_slot = true, 
      copy_data = true, 
      disable_on_error = true);