# Benchmarking

- Create docker external network: ```docker network create external-network```
- Start the `wrk` service: ```docker-compose up -d wrk```
- Access the container: ```docker exec -it benchmarking sh```

## Token context test
Check if the token sent in the request is the same as the one your API is handling and that there is no token leak between sessions.

### Prerequisites
- Application endpoint that returns the following body is required:
```json
{
    "data": {
        "userId": 1,
        "token": "token..."
    }
}
```

### Run command
- Adjust the `.env` by adding the endpoint and the corresponding tokens and user ids: `cp ./token-context/.env.example ./token-context/.env`
- Run the benchmark command: ```./token-context/index.sh```