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
endeavour. I spent a day getting all this working, so hopefully, you won't. All code is available on GitHub.

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

#### Sorry the rest of this blog is still WIP. Come back soon!
<!---
# The Hurdles
1. PostgreSQL Initialization: One of the first challenges was ensuring PostgreSQL initialized correctly. The default 
behavior of the PostgreSQL Docker image is to initialize the data directory and then start the server. However, to 
configure pg_cron, we needed to modify the postgresql.conf file after initialization but before the server started. 
This required overriding the default entrypoint and introducing a custom script to handle the initialization sequence.
2. Running as Root: Docker commands run as root by default. While this is usually convenient, PostgreSQL refuses to 
start as the root user. The solution? Use the su command to switch to the postgres user before starting the server.
3. Directory Permissions: A seemingly trivial issue like the current working directory can lead to unexpected errors. 
For instance, after installing pg_partman, the working directory was inadvertently changed, causing subsequent wget 
commands to fail. The fix? Ensure you're always in a writable directory when attempting to download or write files.
4. Configuration Nuances: pg_cron has a unique requirement: it can only be created in a specific database, as defined 
by the cron.database_name configuration. This necessitated additional environment variables and configuration tweaks to 
ensure compatibility.

# The Solution

After addressing each challenge, the Dockerfile and custom entrypoint script were refined to ensure a smooth setup process. Here's a summarized version of the final approach:

1. Custom Entrypoint: A custom entrypoint script was introduced to handle the PostgreSQL initialization sequence, allowing for modifications to the postgresql.conf file before the server starts. 
2. Explicit User Switching: Before starting PostgreSQL, the script switches to the postgres user to avoid permission issues. 
3. Dynamic Configuration: Environment variables, such as POSTGRES_DB, were leveraged to dynamically set configurations like cron.database_name, ensuring flexibility and ease of use.

# Conclusion

Setting up pg_partman and pg_cron in a Dockerized PostgreSQL environment was not as straightforward as initially anticipated. However, with persistence and a methodical approach to problem-solving, the challenges were overcome. This journey underscores the importance of sharing knowledge and solutions, especially in niche areas where up-to-date resources may be lacking.

For those embarking on similar endeavors, remember: every challenge faced is an opportunity to learn, grow, and contribute back to the community. Happy coding!

--->
