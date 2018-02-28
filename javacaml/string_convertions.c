#include "javacaml_utils.h"

#include <stdint.h>
#include <string.h>

/*
** ========================================================================== **
** Convertion between OCaml strings and Java strings
** OCaml strings are treated as UTF-8 encoded strings
** Java strings as UTF-16 strings
*/

// Decode an UTF-8 character from `str`, put it in `dst`
// Decoding errors will read a single char and return (-1)
// Returns the next position in `str`
static uint32_t		read_utf8(uint8_t const *str, uint32_t *dst)
{
	if (str[0] < 0x80)
	{
		*dst = str[0];
		return 1;
	}
	else if ((str[0] >> 5) == 0x06)
	{
		*dst =	((str[0] & 0x1F) <<  6)
			|	((str[1] & 0x3F) <<  0);
		return 2;
	}
	else if ((str[0] >> 4) == 0x0E)
	{
		*dst =	((str[0] & 0x0F) << 12)
			|	((str[1] & 0x3F) <<  6)
			|	((str[2] & 0x3F) <<  0);
		return 3;
	}
	else if ((str[0] >> 3) == 0x1E)
	{
		*dst =	((str[0] & 0x07) << 18)
			|	((str[1] & 0x3F) << 12)
			|	((str[2] & 0x3F) <<  6)
			|	((str[3] & 0x3F) <<  0);
		return 4;
	}
	else
	{
		*dst = (uint32_t)-1;
		return 1;
	}
}

// Write the UTF-8 representation of `c` in `dst`
// Invalid unicode character be ignored (return 0)
// Returns the next position in `dst`
static uint32_t		write_utf8(uint8_t *dst, uint32_t c)
{
	if (c < 0x80)
	{
		dst[0] = c;
		return 1;
	}
	else if (c < 0x0800)
	{
		dst[0] = ((c >>  6) & 0x1F) | 0xC0;
		dst[1] = ((c >>  0) & 0x3F) | 0x80;
		return 2;
	}
	else if (c < 0x010000)
	{
		dst[0] = ((c >> 12) & 0x0F) | 0xE0;
		dst[1] = ((c >>  6) & 0x3F) | 0x80;
		dst[2] = ((c >>  0) & 0x3F) | 0x80;
		return 3;
	}
	else if (c < 0x110000)
	{
		dst[0] = ((c >> 18) & 0x07) | 0xF0;
		dst[1] = ((c >> 12) & 0x3F) | 0x80;
		dst[2] = ((c >>  6) & 0x3F) | 0x80;
		dst[3] = ((c >>  0) & 0x3F) | 0x80;
		return 4;
	}
	else
	{
		return 0;
	}
}

// Decode an UTF-16 character from `str`, put it in `dst`
// Returns the next position in `str` (in number of char, not byte)
static uint32_t		read_utf16(uint16_t const *str, uint32_t *dst)
{
	if ((str[0] >> 10) == 0xD800)
	{
		*dst = ((str[0] & 0x03FF) << 10) | (str[1] & 0x03FF);
		return 2;
	}
	else
	{
		*dst = str[0];
		return 1;
	}
}

// Write the UTF-16 encoding of `c` in `dst`
// Returns the next position in `dst`
static uint32_t		write_utf16(uint16_t *dst, uint32_t c)
{
	if (c < 0x010000)
	{
		dst[0] = c;
		return 1;
	}
	else if (c < 0x110000)
	{
		dst[0] = ((c - 0x010000) >> 10)	| 0xD800;
		dst[1] = (c & 0x03FF)			| 0xDC00;
		return 2;
	}
	else
	{
		return 0;
	}
}

// UTF-8 to UTF-16
// Allows overflow when calling read_utf8 because OCaml strings are 0-terminated
static uint32_t		utf8_to_utf16(jchar *dst, char const *src, char const *end)
{
	jchar *const		begin = dst;
	uint32_t			c;

	while (src < end)
	{
		src += read_utf8((uint8_t const*)src, &c);
		dst += write_utf16((uint16_t*)dst, c);
	}
	return (dst - begin);
}

// UTF-16 to UTF-8
// May overflow on malformed strings
static uint32_t		utf16_to_utf8(char *dst, jchar const *src, jchar const *end)
{
	char *const			begin = dst;
	uint32_t			c;

	while (src < end)
	{
		src += read_utf16((uint16_t const *)src, &c);
		dst += write_utf8((uint8_t*)dst, c);
	}
	return (dst - begin);
}

value ocaml_java__of_jstring(JNIEnv *env, jstring str)
{
	uint32_t const	length = (*env)->GetStringLength(env, str);
	char			dst[length * 4];
	jchar const		*src;
	uint32_t		dst_length;
	value			result;

	src = (*env)->GetStringChars(env, str, NULL);
	dst_length = utf16_to_utf8(dst, src, src + length);
	(*env)->ReleaseStringChars(env, str, src);
	result = caml_alloc_string(dst_length);
	memcpy((char*)String_val(result), dst, dst_length);
	return result;
}

jstring ocaml_java__to_jstring(JNIEnv *env, value str)
{
	uint32_t const	length = caml_string_length(str);
	jchar			dst[length];
	uint32_t		dst_length;

	dst_length = utf8_to_utf16(dst, String_val(str), String_val(str) + length);
	return (*env)->NewString(env, dst, dst_length);
}
