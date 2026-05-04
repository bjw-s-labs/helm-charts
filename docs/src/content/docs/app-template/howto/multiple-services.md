---
title: "Multiple Services"
description: "How to configure multiple Service objects pointing to one or more controllers"
sidebar:
  label: "Multiple Services"
---

## With a single controller

It is possible to have multiple Service objects that point to a single controller.

### Example

```yaml
controllers:
  main:
    containers:
      main:
        image:
          repository: ghcr.io/mendhak/http-https-echo
          tag: 31
          pullPolicy: IfNotPresent

service:
  main:
    controller: main # Point to the controller with the "main" identifier
    ports:
      http:
        port: 8080
  second:
    controller: main # Point to the controller with the "main" identifier
    ports:
      http:
        port: 8081
```

## With multiple controllers

It is also possible have multiple Service objects that point to different controllers.

### Example

```yaml
controllers:
  main:
    containers:
      main:
        image:
          repository: ghcr.io/mendhak/http-https-echo
          tag: 31
          pullPolicy: IfNotPresent
  second:
    containers:
      main:
        image:
          repository: ghcr.io/mendhak/http-https-echo
          tag: 31
          pullPolicy: IfNotPresent

service:
  main:
    controller: main # Point to the controller with the "main" identifier
    ports:
      http:
        port: 8080
  second:
    controller: main # Point to the controller with the "main" identifier
    ports:
      http:
        port: 8081
  third:
    controller: second # Point to the controller with the "second" identifier
    ports:
      http:
        port: 8081
```
