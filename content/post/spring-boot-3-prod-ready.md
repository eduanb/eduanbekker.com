+++
author = "Eduan Bekker"
title = "Opinion: Reactive Spring Boot 3.0 is not production ready"
date = "2022-01-21"
description = "Weblfux on Spring Boot 3 is not production ready"
tags = [
    "Spring",
    "Kotlin",
]
#thumbnail = "images/hello-world.png"

+++

_Note: This is my opinion, based on the latest Spring Boot 3.0.1.
This is not meant to discredit the hard of anyone involved with Boot 3. It is not just a complaint piece as I offer solutions, and I believe my opinion will change soon._ 

Spring Framework 6 and Spring Boot 3 released in November 2022, covering these 4 major themes:

1. Java 17
2. Jakarta EE 9
3. GraalVM Native Executables
4. Observability
5. HTTP Interfaces

The first 2 were mostly strait forward but large tasks. They are also significant breaking changes, not backwards compatible, and thus warranted new major versions.
From what I can tell, they were both a success. Boot 2.7 already worked great with Java 17; now Boot 3 has native support. I want to point out
the support for records in like, for example, configuration properties. Removing the `@ConstructorBinding` annotation is a win.

I will skip over GraalVM native execution for now, as I do not have production experience with it yet.

The exciting part of this story is observability and HTTP Interfaces.

### What changed with Observability?
A few weeks before the final release of Boot 3, Spring put out this detailed blog about observability in Boot 3. https://spring.io/blog/2022/10/12/observability-with-spring-boot-3
From what I can tell, the two major themes here were:
1. A complete redesign and implementation of tracing
2. Introduction of an observation and the observation API.

And this is where my ma

## What can the team do to reach "Production ready"?
Firstly, document known limitations with links to issues. It is VERY frustrating as a user to follow the docs only to have it not work (trace id in logs).
Secondly, create an official migration guide for observability. Things like dependency changes, configuration changes, deprecated features and current limitations must be precise.
Third, greatly expand the documentation for observability (especially tracing) within the Boot docs. What are common properties to config? Why choose one trace implementation over the other?
Fourth, resolve the missing span IDs in logs. This is a working feature in 2.7, and it is documented as a feature. https://github.com/spring-projects/spring-boot/issues/33372
Lastly, Kotlin Coroutine support in HTTP interfaces. Everything else in Spring portfolio has it.

<br>

---