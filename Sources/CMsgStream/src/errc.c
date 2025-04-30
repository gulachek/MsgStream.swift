/**
 * Copyright 2025 Nicholas Gulachek
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */
#include "msgstream.h"

const char *msgstream_errname(int ec) {
	switch (ec) {
		
		case MSGSTREAM_OK:
			return "MSGSTREAM_OK";
			break;
		
		case MSGSTREAM_EOF:
			return "MSGSTREAM_EOF";
			break;
		
		case MSGSTREAM_NULL_ARG:
			return "MSGSTREAM_NULL_ARG";
			break;
		
		case MSGSTREAM_SMALL_BUF:
			return "MSGSTREAM_SMALL_BUF";
			break;
		
		case MSGSTREAM_SMALL_HDR:
			return "MSGSTREAM_SMALL_HDR";
			break;
		
		case MSGSTREAM_BIG_HDR:
			return "MSGSTREAM_BIG_HDR";
			break;
		
		case MSGSTREAM_HDR_SYNC:
			return "MSGSTREAM_HDR_SYNC";
			break;
		
		case MSGSTREAM_BIG_MSG:
			return "MSGSTREAM_BIG_MSG";
			break;
		
		case MSGSTREAM_SYS_READ_ERR:
			return "MSGSTREAM_SYS_READ_ERR";
			break;
		
		case MSGSTREAM_SYS_WRITE_ERR:
			return "MSGSTREAM_SYS_WRITE_ERR";
			break;
		
		case MSGSTREAM_TRUNC:
			return "MSGSTREAM_TRUNC";
			break;
		
		default:
			return "(Unknown msgstream error code)";
	}
}

const char *msgstream_errstr(int ec) {
	switch (ec) {
		
		case MSGSTREAM_OK:
			return "no error detected";
			break;
		
		case MSGSTREAM_EOF:
			return "end of file";
			break;
		
		case MSGSTREAM_NULL_ARG:
			return "a null pointer was unexpectedly passed as an argument";
			break;
		
		case MSGSTREAM_SMALL_BUF:
			return "buffer is too small";
			break;
		
		case MSGSTREAM_SMALL_HDR:
			return "header size is too small";
			break;
		
		case MSGSTREAM_BIG_HDR:
			return "header size is too big";
			break;
		
		case MSGSTREAM_HDR_SYNC:
			return "header size mismatch between sent and received message";
			break;
		
		case MSGSTREAM_BIG_MSG:
			return "message size is too big";
			break;
		
		case MSGSTREAM_SYS_READ_ERR:
			return "read system call encountered an error";
			break;
		
		case MSGSTREAM_SYS_WRITE_ERR:
			return "write system call encountered an error";
			break;
		
		case MSGSTREAM_TRUNC:
			return "message truncated";
			break;
		
		default:
			return "(Unknown msgstream error code)";
	}
}
