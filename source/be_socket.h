#ifndef BE_SOCKET_H_
#define BE_SOCKET_H_

#ifdef EWINDOWS
    #include <windows.h>

    #ifndef AF_INET
        // Support older version of Watcom < 1.8
    	#include <winsock2.h>
        #include <ws2tcpip.h>
    #endif // AF_INET
	typedef int socklen_t;
#else // ifdef EWINDOWS else
    #include <sys/types.h>
    #include <sys/socket.h>
    #include <netdb.h>
	#include <netinet/in.h>
	#include <arpa/inet.h>

	#ifdef EUNIX
        #include <unistd.h>

		#ifdef EBSD
    		#include <netinet/in.h>
		#endif // EFREEBSD

		#define SOCKET int
		#define SOCKET_ERROR -1
		#define INVALID_SOCKET -1
		#define SOCKADDR struct sockaddr_in
		#define closesocket close
	#endif // UNIX
#endif // ifdef EWINDOWS else

object eusock_info(object x);
object eusock_getservbyname(object x);
object eusock_getservbyport(object x);
object eusock_build_hostent(struct hostent *ent);
object eusock_gethostbyname(object x);
object eusock_gethostbyaddr(object x);
object eusock_error_code();
object eusock_socket(object x);
object eusock_close(object x);
object eusock_shutdown(object x);
object eusock_connect(object x);
object eusock_select(object x);
object eusock_send(object x);
object eusock_recv(object x);
object eusock_sendto(object x);
object eusock_recvfrom(object x);
object eusock_bind(object x);
object eusock_listen(object x);
object eusock_accept(object x);
object eusock_getsockopt(object x);
object eusock_setsockopt(object x);

#endif // BE_SOCKET_H_
