/*
 * Copyright 2009 by OpenEuphoria Group. All Rights Reserved.
 * See License.txt
 */

#include <stdio.h>
#include <stdlib.h>

#ifdef EWINDOWS
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>

extern int default_heap;
#else
#include <sys/socket.h>
#include <netdb.h>
#endif

#include "alldefs.h"
#include "alloc.h"

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
		tempBuff = EMalloc(1024);
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
#else
int eusock_geterror()
{
	return ATOM_0;
}
#endif

/*
 * getservbyname(name, proto)
 */
object eusock_getservbyname(object x)
{
	char *name, *proto;
	s1_ptr name_s, proto_s, result_s;

	struct servent *ent;

#ifdef EWINDOWS
	if (eusock_wsastarted == 0) eusock_wsastart();
#endif

	name_s = SEQ_PTR(SEQ_PTR(x)->base[1]);
	name = EMalloc(name_s->length+1);
	MakeCString(name, SEQ_PTR(x)->base[1] );

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

#ifdef EWINDOWS
	if (eusock_wsastarted == 0) eusock_wsastart();
#endif

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

#ifdef EWINDOWS
	if (eusock_wsastarted == 0) eusock_wsastart();
#endif

	name_s = SEQ_PTR(SEQ_PTR(x)->base[1]);
	name = EMalloc(name_s->length+1);
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

#ifdef EWINDOWS
	if (eusock_wsastarted == 0) eusock_wsastart();
#endif

	address_s = SEQ_PTR(SEQ_PTR(x)->base[1]);
	address = EMalloc(address_s->length+1);
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
