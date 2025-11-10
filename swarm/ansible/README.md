# Docker Swarm Postgres Cluster (Swarmlab expamle company)

> Check `ansible.cfg`, which contains all the defaults.

See [inventory](inventory.yaml) for adding host details.

## Docker swarm setup

Use `pipenv`:

```bash
pipenv shell
pipenv install
```

The following are the playbooks for settig up the Docker Swarm cluster:

```bash
ansible-playbook --vault-id personal@.vault -i inventory.yaml 002_leave.yaml
ansible-playbook --vault-id personal@.vault -i inventory.yaml 001_docker_setup.yaml --tags 'init, network, join' 
```

Some examples (using tags and limiting to an specific host):

```bash
ansible-playbook -i inventory.yaml 001_docker_setup.yaml --tags 'install' -l node3  
```


## Spilo Stack

```bash
ansible-playbook -i inventory.yaml 005_spilo_image.yaml
ansible-playbook -i inventory.yaml 105_spilo_deploy.yaml
```

## Patroni Citus Stack

```bash
ansible-playbook  004_patroni_citus_image.yaml
ansible-playbook  104_patroni_citus_deploy.yaml
```


## TimescaleDB Setup

```bash
ansible-playbook -i inventory.yaml 001_docker_setup.yaml --tags 'copy'
ansible-playbook -i inventory.yaml 100_timescale_stack.yaml 

## Manual steps
cd timescaledb-ha/
docker stack deploy -c docker-stack.yaml  swarmlab
docker stack ps swarmlab
```

