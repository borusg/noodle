# First try
Imperfect, but works.

## How to
- Pick passwords for Elastic, Kibana, and Noodle (pigsfly, dogsfly, dragonsfly)
- Create `.pw/docker-compose.env` based on the [sample](docker-compose.env.sample) and the 3 passwords
- Put the Noodle password in `.pw/docker`
- Build Noodle container: `docker build -t noodle .`
- Start the containers and capture output: `docker-compose --env-file .pw/docker-compose.env up 2>&1 | tee compose-o`
- Test:
    - `export NOODLE_SERVER=localhost:4242`
    - `bin/noodlin create -i host -s moon -p hr -P prod hr.example.com`
    - `bin/noodle ilk=host`
    - `bin/noodle ilk=host full`
- Stop containers and delete volumes: `docker-compose --env-file .pw/docker-compose.env down --volumes`

## Notes
- `docker-compose.yml` is [Elastic's example](https://github.com/elastic/elasticsearch/blob/main/docs/reference/setup/install/docker/docker-compose.yml). It starts 3 Elasticsearch nodes, Kibana, and Noodle
- There are two networks:
    - `backend`: Elastic, Kibana, and Noodle. No ports exposed to host
    - `frontend`: Noodle is exposed to the host on port 4242

## TODO
- Better password handling
- Swarm
- Should setting noodle role password be until loops?
- Noodle isn't using ES certs, but should
- Get Noodle data into Kibana with sample dashboard
- Don't run services as root
- Other [production recommendations](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-prod-prerequisites)
