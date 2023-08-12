+++
author = "Eduan Bekker"
title = "Setting Up pg_partman and pg_cron in Docker"
date = "2022-08-12"
description = "Harder than you think"
tags = [
    "postgres",
    "pg_parman",
    "pg_cron",
    "docker"
]

+++
With the popularity of PostgreSQL, it's often assumed that most problems are solved, documented, and shared on platforms
like Stack Overflow or GitHub. Yet, when diving into the specifics of setting up [pg_partman](https://github.com/pgpartman/pg_partman) and [pg_cron](https://github.com/citusdata/pg_cron) within a
Containerized PostgreSQL environment, it quickly becomes evident that up-to-date, comprehensive guides are surprisingly
scarce. This article aims to fill that gap, detailing the challenges faced and the solutions found during this
endeavour. I spent a day getting all this working, so hopefully, you won't. All code is available on [GitHub](https://github.com/eduanb/eduanbekker.com/tree/main/content/post/pg-partman).

# Understanding Table Partitioning
Table partitioning is a database technique that enhances performance by dividing large tables into smaller, more
manageable segments yet treating them as a single entity. This division can be based on criteria like date ranges or
identifiers. By doing so, queries can run faster as they access fewer data blocks, backups become more efficient, and
older data can be archived or purged seamlessly. Partitioning allows databases to maintain optimal performance as data
volumes grow. Partitioning is particularly powerful in modern ["NewSQL"](https://twitter.com/MarkCallaghanDB/status/1680220294391410688)
tools like AWS's Aurora DB or Google's AlloyDB.

# The Magic of pg_partman and pg_cron
PostgreSQL supports native partitioning. However, it is not easy to set up, maintain or automate. This is where
pg_partman and pg_cron come in. pg_partman is an extension to PostgreSQL that provides automated management of
partitioned tables, including time-based and serial-based table partition sets. pg_partman works on a declarative model.
You define how to partition the data, and pg_partman converts that definition into the appropriate PostgreSQL scripts.
The one part of pg_partman that needs to be added is the continuous enforcement of this desired state.

On the other hand, pg_cron is a job scheduler for PostgreSQL, allowing database administrators to schedule tasks like
periodic data rollups, data retention policies, or even routine maintenance tasks directly from the database.

When combined, pg_partman and pg_cron form a powerful duo. pg_partman can manage the partitions, and pg_cron can be used
to for continuous enforcement.

# Why Docker? The Case for Local Development

It's often recommended to leverage managed services like RDS for production environments. They come with built-in
scalability, automated backups, and maintenance, freeing teams from the operational overhead of managing databases.
Heck, they even [manage extensions like pg_partman and pg_cron for you!](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_Partitions.html).
However, you cannot run that RDS locally or for free. Using Docker for local development, developers can experiment with
these tools without fearing data loss. Need to create or delete partitions? Go ahead. Want to test out a new
partitioning strategy? Docker makes it easy to reset to a default state. This sandboxed environment allows developers to
get hands-on experience with tools like pg_partman and pg_cron, ensuring they're well-prepared before deploying these
tools in a production environment.


# The Hurdles
## Alpine
The standard PostgreSQL image is built with Alpine. Alpine does not have any packages for pg_partman or pp_cron.
These have to be built from the source. To build the C extensions, many tools will need to be installed. From what I could see, this is the list:
```dockerfile
RUN apk add --no-cache \
    autoconf \
    automake \
    g++ \
    clang15 \
    llvm15 \
    libtool \
    libxml2-dev \
    make
```
## Build from source
Since the releases are only gzipped points in time of the source code, we need to build it from source. The steps are:
* Download
* Extract
* make and make install
* cleanup

```bash
wget -O pg_partman.tar.gz "https://github.com/pgpartman/pg_partman/archive/$PG_PARTMAN_VERSION.tar.gz" \
    && mkdir -p /usr/src/pg_partman \
    && tar \
        --extract \
        --file pg_partman.tar.gz \
        --directory /usr/src/pg_partman \
        --strip-components 1 \
    && rm pg_partman.tar.gz \
    && cd /usr/src/pg_partman \
    && make \
    && make install \
    && rm -rf /usr/src/pg_partman
```
Repeat this for pg_cron.
_Note: At this point you can start using pg_partman._

## pg_cron config
If you run the container now and try this:

```sql
CREATE EXTENSION pg_cron
```


You wil see this error:

```
ERROR: unrecognized configuration parameter "cron.database_name"
```

pg_cron has a unique requirement: it can only be created in a specific database, as defined
by the cron.database_name configuration. This necessitated additional environment variables and configuration tweaks to
ensure compatibility. At first, it is tempting to do this:
```dockerfile
RUN echo "shared_preload_libraries = 'pg_cron'" >> /var/lib/postgresql/data/postgresql.conf
RUN echo "cron.database_name = '${PG_CRON_DB:-pg_cron}'" >> /var/lib/postgresql/data/postgresql.conf
```
But this has 2 problems. For 1 the `PG_CRON_DB` variable is now build time. But more important, the standard PostgreSQL
init script will see that `/var/lib/postgresql/data` exists and thinks there is already an DB and startup wil fail
with this error:
```
initdb: error: directory "/var/lib/postgresql/data" exists but is not empty
initdb: hint: If you want to create a new database system, either remove or empty the directory "/var/lib/postgresql/data" or run initdb with an argument other than "/var/lib/postgresql/data".
```
The only solution I've found are these steps:
* Let PostgreSQL start normally
* Shut it down
* Add the pg_cron config
* Start PostgreSQL again

Here is my init script:
```bash
#!/bin/sh

set -e

echo "Starting custom entrypoint..."

# Initialize the database but don't start postgres
docker-entrypoint.sh postgres -h '' &
PID=$!

# Wait for the initialization to complete
echo "Waiting for PostgreSQL to initialize..."
until pg_isready; do
    sleep 1
done

# Stop the temporary PostgreSQL process
echo "Stopping temporary PostgreSQL process..."
kill -s TERM $PID
wait $PID

# Modify the PostgreSQL configuration
echo "Modifying PostgreSQL configuration..."
echo "shared_preload_libraries = 'pg_cron'" >> /var/lib/postgresql/data/postgresql.conf
echo "cron.database_name = '${POSTGRES_DB:-postgres}'" >> /var/lib/postgresql/data/postgresql.conf

echo "Starting PostgreSQL..."
# Has to run as the postgres user
exec su - postgres -c "postgres -D /var/lib/postgresql/data"
``` 

# Create extension
There we have it. Everything should be working now. To test:
```bash
docker build -t partman .
docker run -e POSTGRES_USER=test -e POSTGRES_PASSWORD=test -e POSTGRES_DB=postgres -d -p 5432:5432 --name partman partman
```
Connect to the DB using your favourite tool, or the CLI and run this:
```sql
CREATE SCHEMA partman;
CREATE EXTENSION pg_partman WITH SCHEMA partman;
CREATE EXTENSION pg_cron;
```
No more errors!

# Playing around
Now you can play around with pg_cron and pg_partman. If you mess anything up its as easy as this to start clean:
```bash
docker stop partman; docker rm partman; docker run -e POSTGRES_USER=test -e POSTGRES_PASSWORD=test -e POSTGRES_DB=postgres -d -p 5432:5432 --name partman partman
```
Lets create a table called `my_data`
```sql
CREATE TABLE public.my_data (
  id SERIAL,
  my_date timestamp
) PARTITION BY RANGE (my_date);
```
And then partition it by minutes to make sure it works:
```sql
SELECT partman.create_parent(
  p_parent_table => 'public.my_data',
  p_control => 'my_date',
  p_type => 'native',
  p_interval => '1 minute',
  p_premake => 1,
  p_start_partition => '2023-08-11 14:00:00'
);
```
Now check how many partitions there are:
```sql
select count(*) from partman.show_partitions('public.data');
```
This should be more than 1. If not, play around with the `p_start_partition` and `p_premake`.
At this point, only the parent was created. We need to config it to create infinite partitions:
```sql
UPDATE partman.part_config
SET infinite_time_partitions = true,
    retention = NULL, --- NULL = Infinite
    retention_keep_table=true
WHERE parent_table = 'public.data';
```
If you want to tell pg_partman to enforce its desired state:
````sql
CALL partman.run_maintenance_proc();
````
Or here is the magic, schedule it with pg_cron!
```sql
SELECT cron.schedule('* * * * *', $$CALL partman.run_maintenance_proc()$$);
```

# Conclusion

Setting up pg_partman and pg_cron in a Dockerized PostgreSQL environment was more complex than initially
anticipated. However, with persistence and the challenges were overcome. Now you can play around and get familiar with the
safety of Docker on localhost before going to prod.
