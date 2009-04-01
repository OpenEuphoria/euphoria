/*
 * Copyright 2009 by OpenEuphoria Group. All Rights Reserved.
 * See License.txt
 */

#ifndef EDOS

#include <stdio.h>
#include <stdlib.h>

#ifdef EWINDOWS
#include <windows.h>

#ifndef AF_INET
// Support older version of Watcom < 1.8
#include <winsock2.h>
#include <ws2tcpip.h>
#endif // AF_INET

extern int default_heap;
#else // ifdef EWINDOWS
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#ifdef EUNIX
#include <unistd.h>

#define SOCKET int
#define SOCKET_ERROR -1
#define INVALID_SOCKET -1
#define SOCKADDR struct sockaddr_in
#define closesocket close
#endif // UNIX
#endif // ifdef EWINDOWS else

#include "alldefs.h"
#include "alloc.h"

// Accessors for the socket sequence given to many functions
#define SOCK_SOCKET   1
#define SOCK_SOCKADDR 2

#define BUFF_SIZE 1024

#ifdef EWINDOWS
int eusock_wsastarted = 0;

void eusock_wsastart()
{
	WORD wVersionRequested;
	WSADATA wsaData;
	int err;
	char *tempBuff;

	wVersionRequested = MAKEWORD(2,2);
	err = WSAStartup(wVersionRequested, &wsaData);
	if (err != 0)
	{
		tempBuff = EMalloc(BUFF_SIZE);
		sprintf(tempBuff, "WSAStartup failed with error: %d", err);
		RTFatal(tempBuff);
		EFree(tempBuff);
		return;
	}

	eusock_wsastarted = 1;
}

void eusock_wsacleanup()
{
	WSACleanup();
}

int eusock_geterror()
{
	return WSAGetLastError();
}

#define eusock_ensure_init() if (eusock_wsastarted == 0) eusock_wsastart();

#else // ifdef EWINDOWS
#include <errno.h>
int eusock_geterror()
{
	return errno;
}

#define eusock_ensure_init()
#endif // ifdef EWINDOWS else

/* ============================================================================
 *
 * Information functions
 *
 * ========================================================================== */

/*
 * getservbyname(name, proto)
 */

object eusock_getservbyname(object x)
{
	char *name, *proto;
	s1_ptr name_s, proto_s, result_s;

	struct servent *ent;

	eusock_ensure_init();

	name_s = SEQ_PTR(SEQ_PTR(x)->base[1]);
	name   = EMalloc(name_s->length+1);
	MakeCString(name, SEQ_PTR(x)->base[1] );

	if (IS_SEQUENCE(SEQ_PTR(x)->base[2]))
	{
		proto_s = SEQ_PTR(SEQ_PTR(x)->base[2]);
		proto = EMalloc(proto_s->length+1);
		MakeCString(proto, SEQ_PTR(x)->base[2]);
	}
	else
	{
		proto = 0;
	}

	// ent is static data, do not free
	ent = getservbyname(name, proto);

	EFree(name);
	if (proto != 0)
	{
		EFree(proto);
	}

	if (ent == NULL)
	{
		return eusock_geterror();
	}

	result_s = NewS1(3); // official name, port
	result_s->base[1] = NewString(ent->s_name);
	result_s->base[2] = NewString(ent->s_proto);
	result_s->base[3] = htons(ent->s_port);

	return MAKE_SEQ(result_s);
}

/*
 * getservbyport(port, proto)
 */

object eusock_getservbyport(object x)
{
	char *proto;
	int port;
	s1_ptr proto_s, result_s;

	struct servent *ent;

	eusock_ensure_init();

	port = SEQ_PTR(x)->base[1];

	if (IS_SEQUENCE(SEQ_PTR(SEQ_PTR(x)->base[2])))
	{
		proto_s = SEQ_PTR(SEQ_PTR(x)->base[2]);
		proto = EMalloc(proto_s->length+1);
		MakeCString(proto, SEQ_PTR(x)->base[2]);
	}
	else
	{
		proto = 0;
	}

	// ent is static data, do not free
	ent = getservbyport(ntohs(port), proto);

	if (proto != 0)
	{
		EFree(proto);
	}

	if (ent == NULL)
	{
		return eusock_geterror();
	}

	result_s = NewS1(3); // official name, port
	result_s->base[1] = NewString(ent->s_name);
	result_s->base[2] = NewString(ent->s_proto);
	result_s->base[3] = htons(ent->s_port);

	return MAKE_SEQ(result_s);
}

object eusock_build_hostent(struct hostent *ent)
{
	char **aliases;
	int count;
	s1_ptr aliases_s, ips_s, result_s;

	struct in_addr addr;

	if (ent == NULL)
	{
		return eusock_geterror();
	}

	count = 0;
	for (aliases = ent->h_aliases; *aliases != 0; aliases++)
	{
		count += 1;
	}

	aliases_s = NewS1(count);
	count = 1;
	aliases = ent->h_aliases;
	while (*aliases != 0) {
		aliases_s->base[count] = NewString(*aliases);

		aliases++;
		count += 1;
	}

	count = 0;
	while (ent->h_addr_list[count] != 0)
	{
		count += 1;
	}

	ips_s = NewS1(count);
	count = 0;
	while (ent->h_addr_list[count] != 0)
	{
		addr.s_addr = * (u_long *) ent->h_addr_list[count];
		ips_s->base[count+1] = NewString(inet_ntoa(addr));
		count += 1;
	}

	result_s = NewS1(4); // official name, alias names, ip addresses, address type
	result_s->base[1] = NewString(ent->h_name);
	result_s->base[2] = MAKE_SEQ(aliases_s);
	result_s->base[3] = MAKE_SEQ(ips_s);
	result_s->base[4] = ent->h_addrtype;

	return MAKE_SEQ(result_s);
}

/*
 * gethostbyname(name)
 */

object eusock_gethostbyname(object x)
{
	char *name;
	int count;
	s1_ptr name_s;

	struct hostent *ent;

	eusock_ensure_init();

	name_s = SEQ_PTR(SEQ_PTR(x)->base[1]);
	name   = EMalloc(name_s->length+1);
	MakeCString(name, SEQ_PTR(x)->base[1] );

	// ent is static data, do not free
	ent = gethostbyname(name);

	EFree(name);

	return eusock_build_hostent(ent);
}

/*
 * gethostbyaddr(addr)
 */

object eusock_gethostbyaddr(object x)
{
	char *address;
	s1_ptr address_s;

	struct hostent *ent;
	struct in_addr addr;

	eusock_ensure_init();

	address_s = SEQ_PTR(SEQ_PTR(x)->base[1]);
	address   = EMalloc(address_s->length+1);
	MakeCString(address, SEQ_PTR(x)->base[1] );

	addr.s_addr = inet_addr(address);
	if (addr.s_addr == INADDR_NONE)
	{
		// TODO: Give a real error message
		return ATOM_0;
	}

	// ent is static data, do not free
	ent = gethostbyaddr((char *) &addr, 4, AF_INET);

	EFree(address);

	return eusock_build_hostent(ent);
}

/* ============================================================================
 *
 * Shared Client/Server functions
 *
 * ========================================================================== */

/*
 * socket(af, type, protocol)
 *
 * return { socket, sockaddr_in }
 */

object eusock_socket(object x)
{
	int af, type, protocol;
	SOCKET sock;
	struct sockaddr_in *addr;

	s1_ptr result_p;

	eusock_ensure_init();

	af       = SEQ_PTR(x)->base[1];
	type     = SEQ_PTR(x)->base[2];
	protocol = SEQ_PTR(x)->base[3];

	sock = socket(af, type, protocol);
	if (sock == INVALID_SOCKET)
	{
		return eusock_geterror();
	}

	addr = EMalloc(sizeof(addr));
	addr->sin_family = af;
	addr->sin_port   = 0;

	result_p = NewS1(2);
	result_p->base[1] = sock;

	if ((unsigned) addr > (unsigned)MAXINT)
		result_p->base[2] = NewDouble((double)(unsigned long) addr);
	else
		result_p->base[2] = addr;

	return MAKE_SEQ(result_p);
}

/*
 * close(sock)
 */

object eusock_close(object x)
{
	SOCKET s;

	s = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];

	if (closesocket(s) == SOCKET_ERROR)
	{
		return eusock_geterror();
	}

	return ATOM_1;
}

/*
 * shutdown(sock, how)
 */

object eusock_shutdown(object x)
{
	SOCKET s;
	int how;

	s = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];
	how = SEQ_PTR(x)->base[2];

	if (shutdown(s, how) == SOCKET_ERROR)
	{
		return eusock_geterror();
	}

	return ATOM_1;
}

/*
 * connect(sock, address, port)
 */

object eusock_connect(object x)
{
	SOCKET s;
	struct sockaddr_in *addr;
	int result;

	s1_ptr address_s;
	char *address;

	eusock_ensure_init();

	s    = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];
	addr = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKADDR];

	addr->sin_port = htons(SEQ_PTR(x)->base[3]);

	address_s = SEQ_PTR(SEQ_PTR(x)->base[2]);
	address   = EMalloc(address_s->length+1);
	MakeCString(address, SEQ_PTR(x)->base[2]);

	addr->sin_addr.s_addr = inet_addr(address);
	if (addr->sin_addr.s_addr == INADDR_NONE)
	{
		// TODO: Give a real error message
		return ATOM_0;
	}

	result = connect(s, addr, sizeof(SOCKADDR));

	EFree(address);

	if (result == SOCKET_ERROR)
	{
		return eusock_geterror();
	}

	return ATOM_1;
}

/*
 * send(sock, buf, flags)
 */

object eusock_send(object x)
{
	SOCKET s;
	int flags, result;

	s1_ptr buf_s;
	char *buf;

	s     = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];
	flags = SEQ_PTR(x)->base[3];

	buf_s = SEQ_PTR(SEQ_PTR(x)->base[2]);
	buf   = EMalloc(buf_s->length+1);
	MakeCString(buf, SEQ_PTR(x)->base[2]);

	result = send(s, buf, buf_s->length, flags);

	EFree(buf);

	if (result == SOCKET_ERROR)
	{
		return eusock_geterror();
	}

	return result;
}

/*
 * recv(sock, flags)
 */

object eusock_recv(object x)
{
	SOCKET s;
	int flags, result;
	char buf[BUFF_SIZE];

	s     = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];
	flags = SEQ_PTR(x)->base[2];

	result = recv(s, buf, BUFF_SIZE, flags);

	if (result > 0)
	{
		buf[result] = 0;
		return NewString(buf);
	} else if (result == 0) {
		return ATOM_0;
	} else {
		return eusock_geterror();
	}
}

/* ============================================================================
 *
 * Server functions
 *
 * ========================================================================== */

/*
 * bind(socket, address, port)
 */

object eusock_bind(object x)
{
	SOCKET s;
	s1_ptr address_s;
	char *address;
	int port, result;

	struct sockaddr_in *service;

	eusock_ensure_init();

	s       = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];
	service = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKADDR];
	port    = SEQ_PTR(x)->base[3];

	address_s = SEQ_PTR(SEQ_PTR(x)->base[2]);
	address   = EMalloc(address_s->length+1);
	MakeCString(address, SEQ_PTR(x)->base[2]);

	service->sin_addr.s_addr = inet_addr(address);
	service->sin_port        = htons(port);

	result = bind(s, service, sizeof(SOCKADDR));

	EFree(address);

	if (result == SOCKET_ERROR)
	{
	  return eusock_geterror();
	}

	return ATOM_1;
}

/*
 * listen(socket, backlog)
 */

object eusock_listen(object x)
{
	SOCKET s;
	int backlog;

	s       = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];
	backlog = SEQ_PTR(x)->base[2];

	if (listen(s, backlog) == SOCKET_ERROR)
	{
		return eusock_geterror();
	}

	return ATOM_1;
}

/*
 * accept(socket)
 */

object eusock_accept(object x)
{
	SOCKET server, client;
	struct sockaddr_in addr;
	int addr_len;

	s1_ptr client_seq, client_sock_p;

	server = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];

	addr_len = sizeof(addr);
	client   = accept(server, &addr, &addr_len);

	if (client == INVALID_SOCKET)
	{
		return eusock_geterror();
	}

	client_sock_p = NewS1(2);
	client_sock_p->base[1] = client;
	client_sock_p->base[2] = 0;

	client_seq = NewS1(2);
	client_seq->base[1] = MAKE_SEQ(client_sock_p);
	client_seq->base[2] = NewString(inet_ntoa(addr.sin_addr));

	return MAKE_SEQ(client_seq);
}

/*
 * getsockopt(socket, level, optname)
 */

object eusock_getsockopt(object x)
{
	SOCKET s;
	int level, optname, optlen, optval;

	optlen  = sizeof(int);
	s       = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];
	level   = SEQ_PTR(x)->base[2];
	optname = SEQ_PTR(x)->base[3];

	if (getsockopt(s, level, optname, (char *) &optval, &optlen) == SOCKET_ERROR)
	{
		return eusock_geterror();
	}

	return optval;
}

/*
 * setsockopt(socket, level, optname, value)
 */

object eusock_setsockopt(object x)
{
	SOCKET s;
	int level, optname, optlen, optval;

	optlen  = sizeof(int);
	s       = SEQ_PTR(SEQ_PTR(x)->base[1])->base[SOCK_SOCKET];
	level   = SEQ_PTR(x)->base[2];
	optname = SEQ_PTR(x)->base[3];
	optval  = SEQ_PTR(x)->base[4];

	if (setsockopt(s, level, optname, (char *) &optval, &optlen) == SOCKET_ERROR)
	{
		return eusock_geterror();
	}

	return optval;
}

/*
 * select({ socket, ... }, timeout)
 */

object eusock_select(object x)
{
	SOCKET tmp_socket;
	int i, timeout, result, max_sock;
	fd_set readable, writable, errd;
	struct timeval tv_timeout;

	s1_ptr socks_p, result_p, tmp_sp;

	socks_p = SEQ_PTR(SEQ_PTR(x)->base[1]);
	timeout = SEQ_PTR(x)->base[2];
	max_sock = 0;

	// prepare our fd_set
	FD_ZERO(&readable);
	FD_ZERO(&writable);
	FD_ZERO(&errd);

	for (i=1; i <= socks_p->length; i++) {
		tmp_socket = SEQ_PTR(socks_p->base[i])->base[SOCK_SOCKET];

		FD_SET(tmp_socket, &readable);
		FD_SET(tmp_socket, &writable);
		FD_SET(tmp_socket, &errd);

		max_sock = (max_sock > tmp_socket) ? max_sock : tmp_socket;
	}

	tv_timeout.tv_sec = 0;
	tv_timeout.tv_usec = timeout;

	result = select(max_sock + 1, &readable, &writable, &errd, &tv_timeout);

	if (result == -1) {
		return eusock_geterror();
	}

	result_p = NewS1(socks_p->length);
	for (i=1; i <= socks_p->length; i++) {
		tmp_socket = SEQ_PTR(socks_p->base[i])->base[SOCK_SOCKET];

		tmp_sp = NewS1(4);
		tmp_sp->base[1] = socks_p->base[i];
		tmp_sp->base[2] = FD_ISSET(tmp_socket, &readable);
		tmp_sp->base[3] = FD_ISSET(tmp_socket, &writable);
		tmp_sp->base[4] = FD_ISSET(tmp_socket, &errd);

		result_p->base[i] = MAKE_SEQ(tmp_sp);
	}

	return MAKE_SEQ(result_p);
}

#endif // ifndef EDOS
