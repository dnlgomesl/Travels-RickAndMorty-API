FROM crystallang/crystal:1.8.2-alpine

WORKDIR /app

COPY shard.yml .
COPY shard.lock .

RUN shards install

COPY . .

CMD ["crystal", "run", "src/app.cr"]