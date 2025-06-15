# Benchmarking

A simple benchmarking for testing authenticated HTTP requests.  
Provide the user ID, token, and request payload, then run the benchmark and view the results.  
Ideal for quickly stress-testing endpoints that require authentication.

## Setup
- Create docker external network (if your application to test is a docker container in another docker compose): ```docker network create external-network```
- Start the service: ```docker compose up -d```
- Adjust `.env` by configuring your own specifications: `cp .env.example .env`
- Adjust `users.json` by configuring your own requests: `cp users.example.json users.json`
- Access the container: ```docker exec -it benchmarking sh```
- Run the benchmark command: ```bash index.sh```
