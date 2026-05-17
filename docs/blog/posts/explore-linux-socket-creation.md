---
date: 
 created: 2026-03-28
authors:
 - jatin
draft: true
categories:
 - linux-kernel 
---


# Explore Linux: Socket creation 

## Objective

- to explore socket creation, exploring `SOCKET_SYSCALL`
- to understand what happens, when `socket()` from user-space is called

<!-- more -->


## Exploration

Socket syscall is defined in `/net/socket.c`

```c
SYSCALL_DEFINE3(socket, int, family, int, type, int, protocol)
{
	return __sys_socket(family, type, protocol);
}

```




