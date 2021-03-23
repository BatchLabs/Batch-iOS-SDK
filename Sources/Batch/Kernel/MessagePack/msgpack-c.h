/*
The MIT License (MIT)

Copyright (c) 2017 Charles Gunyon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#ifndef BAT_CMP_H__
#define BAT_CMP_H__

struct bat_cmp_ctx_s;

typedef bool   (*bat_cmp_reader)(struct bat_cmp_ctx_s *ctx, void *data, size_t limit);
typedef bool   (*bat_cmp_skipper)(struct bat_cmp_ctx_s *ctx, size_t count);
typedef size_t (*bat_cmp_writer)(struct bat_cmp_ctx_s *ctx, const void *data,
                                                    size_t count);

enum {
  BAT_CMP_TYPE_POSITIVE_FIXNUM, /*  0 */
  BAT_CMP_TYPE_FIXMAP,          /*  1 */
  BAT_CMP_TYPE_FIXARRAY,        /*  2 */
  BAT_CMP_TYPE_FIXSTR,          /*  3 */
  BAT_CMP_TYPE_NIL,             /*  4 */
  BAT_CMP_TYPE_BOOLEAN,         /*  5 */
  BAT_CMP_TYPE_BIN8,            /*  6 */
  BAT_CMP_TYPE_BIN16,           /*  7 */
  BAT_CMP_TYPE_BIN32,           /*  8 */
  BAT_CMP_TYPE_EXT8,            /*  9 */
  BAT_CMP_TYPE_EXT16,           /* 10 */
  BAT_CMP_TYPE_EXT32,           /* 11 */
  BAT_CMP_TYPE_FLOAT,           /* 12 */
  BAT_CMP_TYPE_DOUBLE,          /* 13 */
  BAT_CMP_TYPE_UINT8,           /* 14 */
  BAT_CMP_TYPE_UINT16,          /* 15 */
  BAT_CMP_TYPE_UINT32,          /* 16 */
  BAT_CMP_TYPE_UINT64,          /* 17 */
  BAT_CMP_TYPE_SINT8,           /* 18 */
  BAT_CMP_TYPE_SINT16,          /* 19 */
  BAT_CMP_TYPE_SINT32,          /* 20 */
  BAT_CMP_TYPE_SINT64,          /* 21 */
  BAT_CMP_TYPE_FIXEXT1,         /* 22 */
  BAT_CMP_TYPE_FIXEXT2,         /* 23 */
  BAT_CMP_TYPE_FIXEXT4,         /* 24 */
  BAT_CMP_TYPE_FIXEXT8,         /* 25 */
  BAT_CMP_TYPE_FIXEXT16,        /* 26 */
  BAT_CMP_TYPE_STR8,            /* 27 */
  BAT_CMP_TYPE_STR16,           /* 28 */
  BAT_CMP_TYPE_STR32,           /* 29 */
  BAT_CMP_TYPE_ARRAY16,         /* 30 */
  BAT_CMP_TYPE_ARRAY32,         /* 31 */
  BAT_CMP_TYPE_MAP16,           /* 32 */
  BAT_CMP_TYPE_MAP32,           /* 33 */
  BAT_CMP_TYPE_NEGATIVE_FIXNUM  /* 34 */
};

enum {
    BATCMP_ERROR_NONE,
    BATCMP_STR_DATA_LENGTH_TOO_LONG_ERROR,
    BATCMP_BIN_DATA_LENGTH_TOO_LONG_ERROR,
    BATCMP_ARRAY_LENGTH_TOO_LONG_ERROR,
    BATCMP_MAP_LENGTH_TOO_LONG_ERROR,
    BATCMP_INPUT_VALUE_TOO_LARGE_ERROR,
    BATCMP_FIXED_VALUE_WRITING_ERROR,
    BATCMP_TYPE_MARKER_READING_ERROR,
    BATCMP_TYPE_MARKER_WRITING_ERROR,
    BATCMP_DATA_READING_ERROR,
    BATCMP_DATA_WRITING_ERROR,
    BATCMP_EXT_TYPE_READING_ERROR,
    BATCMP_EXT_TYPE_WRITING_ERROR,
    BATCMP_INVALID_TYPE_ERROR,
    BATCMP_LENGTH_READING_ERROR,
    BATCMP_LENGTH_WRITING_ERROR,
    BATCMP_SKIP_DEPTH_LIMIT_EXCEEDED_ERROR,
    BATCMP_INTERNAL_ERROR,
    BATCMP_ERROR_MAX
};

typedef struct bat_cmp_ext_s {
  int8_t type;
  uint32_t size;
} bat_cmp_ext_t;

union bat_cmp_object_data_u {
  bool      boolean;
  uint8_t   u8;
  uint16_t  u16;
  uint32_t  u32;
  uint64_t  u64;
  int8_t    s8;
  int16_t   s16;
  int32_t   s32;
  int64_t   s64;
  float     flt;
  double    dbl;
  uint32_t  array_size;
  uint32_t  map_size;
  uint32_t  str_size;
  uint32_t  bin_size;
  bat_cmp_ext_t ext;
};

typedef struct bat_cmp_ctx_s {
  uint8_t      error;
  void        *buf;
  bat_cmp_reader   read;
  bat_cmp_skipper  skip;
  bat_cmp_writer   write;
} bat_cmp_ctx_t;

typedef struct bat_cmp_object_s {
  uint8_t type;
  union bat_cmp_object_data_u as;
} bat_cmp_object_t;

/*
 * ============================================================================
 * === Main API
 * ============================================================================
 */

/*
 * Initializes a CMP context
 *
 * If you don't intend to read, `read` may be NULL, but calling `*read*`
 * functions will crash; there is no check.
 *
 * `skip` may be NULL, in which case skipping functions will use `read`.
 *
 * If you don't intend to write, `write` may be NULL, but calling `*write*`
 * functions will crash; there is no check.
 */
void bat_cmp_init(bat_cmp_ctx_t *ctx, void *buf, bat_cmp_reader read,
                                         bat_cmp_skipper skip,
                                         bat_cmp_writer write);

/* Returns CMP's version */
uint32_t bat_cmp_version(void);

/* Returns the MessagePack version employed by CMP */
uint32_t bat_cmp_mp_version(void);

/* Returns a string description of a CMP context's error */
const char* bat_cmp_strerror(bat_cmp_ctx_t *ctx);

/* Writes a signed integer to the backend */
bool bat_cmp_write_integer(bat_cmp_ctx_t *ctx, int64_t d);

/* Writes an unsigned integer to the backend */
bool bat_cmp_write_uinteger(bat_cmp_ctx_t *ctx, uint64_t u);

/*
 * Writes a floating-point value (either single or double-precision) to the
 * backend
 */
bool bat_cmp_write_decimal(bat_cmp_ctx_t *ctx, double d);

/* Writes NULL to the backend */
bool bat_cmp_write_nil(bat_cmp_ctx_t *ctx);

/* Writes true to the backend */
bool bat_cmp_write_true(bat_cmp_ctx_t *ctx);

/* Writes false to the backend */
bool bat_cmp_write_false(bat_cmp_ctx_t *ctx);

/* Writes a boolean value to the backend */
bool bat_cmp_write_bool(bat_cmp_ctx_t *ctx, bool b);

/*
 * Writes an unsigned char's value to the backend as a boolean.  This is useful
 * if you are using a different boolean type in your application.
 */
bool bat_cmp_write_u8_as_bool(bat_cmp_ctx_t *ctx, uint8_t b);

/*
 * Writes a string to the backend; according to the MessagePack spec, this must
 * be encoded using UTF-8, but CMP leaves that job up to the programmer.
 */
bool bat_cmp_write_str(bat_cmp_ctx_t *ctx, const char *data, uint32_t size);

/*
 * Writes a string to the backend.  This avoids using the STR8 marker, which
 * is unsupported by MessagePack v4, the version implemented by many other
 * MessagePack libraries.  No encoding is assumed in this case, not that it
 * matters.
 */
bool bat_cmp_write_str_v4(bat_cmp_ctx_t *ctx, const char *data, uint32_t size);

/*
 * Writes the string marker to the backend.  This is useful if you are writing
 * data in chunks instead of a single shot.
 */
bool bat_cmp_write_str_marker(bat_cmp_ctx_t *ctx, uint32_t size);

/*
 * Writes the string marker to the backend.  This is useful if you are writing
 * data in chunks instead of a single shot.  This avoids using the STR8
 * marker, which is unsupported by MessagePack v4, the version implemented by
 * many other MessagePack libraries.  No encoding is assumed in this case, not
 * that it matters.
 */
bool bat_cmp_write_str_marker_v4(bat_cmp_ctx_t *ctx, uint32_t size);

/* Writes binary data to the backend */
bool bat_cmp_write_bin(bat_cmp_ctx_t *ctx, const void *data, uint32_t size);

/*
 * Writes the binary data marker to the backend.  This is useful if you are
 * writing data in chunks instead of a single shot.
 */
bool bat_cmp_write_bin_marker(bat_cmp_ctx_t *ctx, uint32_t size);

/* Writes an array to the backend. */
bool bat_cmp_write_array(bat_cmp_ctx_t *ctx, uint32_t size);

/* Writes a map to the backend. */
bool bat_cmp_write_map(bat_cmp_ctx_t *ctx, uint32_t size);

/* Writes an extended type to the backend */
bool bat_cmp_write_ext(bat_cmp_ctx_t *ctx, int8_t type, uint32_t size,
                                   const void *data);

/*
 * Writes the extended type marker to the backend.  This is useful if you want
 * to write the type's data in chunks instead of a single shot.
 */
bool bat_cmp_write_ext_marker(bat_cmp_ctx_t *ctx, int8_t type, uint32_t size);

/* Writes an object to the backend */
bool bat_cmp_write_object(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj);

/*
 * Writes an object to the backend. This avoids using the STR8 marker, which
 * is unsupported by MessagePack v4, the version implemented by many other
 * MessagePack libraries.
 */
bool bat_cmp_write_object_v4(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj);

/* Reads a signed integer that fits inside a signed char */
bool bat_cmp_read_char(bat_cmp_ctx_t *ctx, int8_t *c);

/* Reads a signed integer that fits inside a signed short */
bool bat_cmp_read_short(bat_cmp_ctx_t *ctx, int16_t *s);

/* Reads a signed integer that fits inside a signed int */
bool bat_cmp_read_int(bat_cmp_ctx_t *ctx, int32_t *i);

/* Reads a signed integer that fits inside a signed long */
bool bat_cmp_read_long(bat_cmp_ctx_t *ctx, int64_t *d);

/* Reads a signed integer */
bool bat_cmp_read_integer(bat_cmp_ctx_t *ctx, int64_t *d);

/* Reads an unsigned integer that fits inside an unsigned char */
bool bat_cmp_read_uchar(bat_cmp_ctx_t *ctx, uint8_t *c);

/* Reads an unsigned integer that fits inside an unsigned short */
bool bat_cmp_read_ushort(bat_cmp_ctx_t *ctx, uint16_t *s);

/* Reads an unsigned integer that fits inside an unsigned int */
bool bat_cmp_read_uint(bat_cmp_ctx_t *ctx, uint32_t *i);

/* Reads an unsigned integer that fits inside an unsigned long */
bool bat_cmp_read_ulong(bat_cmp_ctx_t *ctx, uint64_t *u);

/* Reads an unsigned integer */
bool bat_cmp_read_uinteger(bat_cmp_ctx_t *ctx, uint64_t *u);

/*
 * Reads a floating point value (either single or double-precision) from the
 * backend
 */
bool bat_cmp_read_decimal(bat_cmp_ctx_t *ctx, double *d);

/* "Reads" (more like "skips") a NULL value from the backend */
bool bat_cmp_read_nil(bat_cmp_ctx_t *ctx);

/* Reads a boolean from the backend */
bool bat_cmp_read_bool(bat_cmp_ctx_t *ctx, bool *b);

/*
 * Reads a boolean as an unsigned char from the backend; this is useful if your
 * application uses a different boolean type.
 */
bool bat_cmp_read_bool_as_u8(bat_cmp_ctx_t *ctx, uint8_t *b);

/* Reads a string's size from the backend */
bool bat_cmp_read_str_size(bat_cmp_ctx_t *ctx, uint32_t *size);

/*
 * Reads a string from the backend; according to the spec, the string's data
 * ought to be encoded using UTF-8, 
 */
bool bat_cmp_read_str(bat_cmp_ctx_t *ctx, char *data, uint32_t *size);

/* Reads the size of packed binary data from the backend */
bool bat_cmp_read_bin_size(bat_cmp_ctx_t *ctx, uint32_t *size);

/* Reads packed binary data from the backend */
bool bat_cmp_read_bin(bat_cmp_ctx_t *ctx, void *data, uint32_t *size);

/* Reads an array from the backend */
bool bat_cmp_read_array(bat_cmp_ctx_t *ctx, uint32_t *size);

/* Reads a map from the backend */
bool bat_cmp_read_map(bat_cmp_ctx_t *ctx, uint32_t *size);

/* Reads the extended type's marker from the backend */
bool bat_cmp_read_ext_marker(bat_cmp_ctx_t *ctx, int8_t *type, uint32_t *size);

/* Reads an extended type from the backend */
bool bat_cmp_read_ext(bat_cmp_ctx_t *ctx, int8_t *type, uint32_t *size, void *data);

/* Reads an object from the backend */
bool bat_cmp_read_object(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj);

/*
 * Skips the next object from the backend.  If that object is an array or map,
 * this function will:
 *   - If `obj` is not `NULL`, fill in `obj` with that object
 *   - Set `ctx->error` to `BATCMP_SKIP_DEPTH_LIMIT_EXCEEDED_ERROR`
 *   - Return `false`
 * Otherwise:
 *   - (Don't touch `obj`)
 *   - Return `true`
 */
bool bat_cmp_skip_object(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj);

/*
 * This is similar to `bat_cmp_skip_object_flat`, except it tolerates flat arrays
 * and maps.  If when skipping such an array or map this function encounteres
 * another array/map, it will:
 *   - If `obj` is not `NULL`, fill in `obj` with that (nested) object
 *   - Set `ctx->error` to `BATCMP_SKIP_DEPTH_LIMIT_EXCEEDED_ERROR`
 *   - Return `false`
 * Otherwise:
 *   - (Don't touch `obj`)
 *   - Return `true`
 */
bool bat_cmp_skip_object_flat(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj);

/*
 * WARNING: THIS FUNCTION IS DEPRECATED AND WILL BE REMOVED IN A FUTURE RELEASE
 *
 * There is no way to track depths across elements without allocation.  For
 * example, an array constructed as: `[ [] [] [] [] [] [] [] [] [] [] ]`
 * should be able to be skipped with `bat_cmp_skip_object_limit(&cmp, &obj, 2)`.
 * However, because we cannot track depth across the elements, there's no way
 * to reset it after descending down into each element.
 *
 * This is similar to `bat_cmp_skip_object`, except it tolerates up to `limit`
 * levels of nesting.  For example, in order to skip an array that contains a
 * map, call `bat_cmp_skip_object_limit(ctx, &obj, 2)`.  Or in other words,
 * `bat_cmp_skip_object(ctx, &obj)` acts similarly to `bat_cmp_skip_object_limit(ctx,
 * &obj, 0)`
 *
 * Specifically, `limit` refers to depth, not breadth.  So in order to skip an
 * array that contains two arrays that each contain 3 strings, you would call
 * `bat_cmp_skip_object_limit(ctx, &obj, 2).  In order to skip an array that
 * contains 4 arrays that each contain 1 string, you would still call
 * `bat_cmp_skip_object_limit(ctx, &obj, 2).
 */
bool bat_cmp_skip_object_limit(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj, uint32_t limit)
#ifdef __GNUC__
  __attribute__((deprecated))
#endif
;

#ifdef _MSC_VER
#pragma deprecated(bat_cmp_skip_object_limit)
#endif

/*
 * This is similar to `bat_cmp_skip_object`, except it will continually skip
 * nested data structures.
 *
 * WARNING: This can cause your application to spend an unbounded amount of
 *          time reading nested data structures.  Unless you completely trust
 *          the data source, you should strongly consider `bat_cmp_skip_object` or
 *          `bat_cmp_skip_object_limit`.
 */
bool bat_cmp_skip_object_no_limit(bat_cmp_ctx_t *ctx);

/*
 * ============================================================================
 * === Specific API
 * ============================================================================
 */

bool bat_cmp_write_pfix(bat_cmp_ctx_t *ctx, uint8_t c);
bool bat_cmp_write_nfix(bat_cmp_ctx_t *ctx, int8_t c);

bool bat_cmp_write_sfix(bat_cmp_ctx_t *ctx, int8_t c);
bool bat_cmp_write_s8(bat_cmp_ctx_t *ctx, int8_t c);
bool bat_cmp_write_s16(bat_cmp_ctx_t *ctx, int16_t s);
bool bat_cmp_write_s32(bat_cmp_ctx_t *ctx, int32_t i);
bool bat_cmp_write_s64(bat_cmp_ctx_t *ctx, int64_t l);

bool bat_cmp_write_ufix(bat_cmp_ctx_t *ctx, uint8_t c);
bool bat_cmp_write_u8(bat_cmp_ctx_t *ctx, uint8_t c);
bool bat_cmp_write_u16(bat_cmp_ctx_t *ctx, uint16_t s);
bool bat_cmp_write_u32(bat_cmp_ctx_t *ctx, uint32_t i);
bool bat_cmp_write_u64(bat_cmp_ctx_t *ctx, uint64_t l);

bool bat_cmp_write_float(bat_cmp_ctx_t *ctx, float f);
bool bat_cmp_write_double(bat_cmp_ctx_t *ctx, double d);

bool bat_cmp_write_fixstr_marker(bat_cmp_ctx_t *ctx, uint8_t size);
bool bat_cmp_write_fixstr(bat_cmp_ctx_t *ctx, const char *data, uint8_t size);
bool bat_cmp_write_str8_marker(bat_cmp_ctx_t *ctx, uint8_t size);
bool bat_cmp_write_str8(bat_cmp_ctx_t *ctx, const char *data, uint8_t size);
bool bat_cmp_write_str16_marker(bat_cmp_ctx_t *ctx, uint16_t size);
bool bat_cmp_write_str16(bat_cmp_ctx_t *ctx, const char *data, uint16_t size);
bool bat_cmp_write_str32_marker(bat_cmp_ctx_t *ctx, uint32_t size);
bool bat_cmp_write_str32(bat_cmp_ctx_t *ctx, const char *data, uint32_t size);

bool bat_cmp_write_bin8_marker(bat_cmp_ctx_t *ctx, uint8_t size);
bool bat_cmp_write_bin8(bat_cmp_ctx_t *ctx, const void *data, uint8_t size);
bool bat_cmp_write_bin16_marker(bat_cmp_ctx_t *ctx, uint16_t size);
bool bat_cmp_write_bin16(bat_cmp_ctx_t *ctx, const void *data, uint16_t size);
bool bat_cmp_write_bin32_marker(bat_cmp_ctx_t *ctx, uint32_t size);
bool bat_cmp_write_bin32(bat_cmp_ctx_t *ctx, const void *data, uint32_t size);

bool bat_cmp_write_fixarray(bat_cmp_ctx_t *ctx, uint8_t size);
bool bat_cmp_write_array16(bat_cmp_ctx_t *ctx, uint16_t size);
bool bat_cmp_write_array32(bat_cmp_ctx_t *ctx, uint32_t size);

bool bat_cmp_write_fixmap(bat_cmp_ctx_t *ctx, uint8_t size);
bool bat_cmp_write_map16(bat_cmp_ctx_t *ctx, uint16_t size);
bool bat_cmp_write_map32(bat_cmp_ctx_t *ctx, uint32_t size);

bool bat_cmp_write_fixext1_marker(bat_cmp_ctx_t *ctx, int8_t type);
bool bat_cmp_write_fixext1(bat_cmp_ctx_t *ctx, int8_t type, const void *data);
bool bat_cmp_write_fixext2_marker(bat_cmp_ctx_t *ctx, int8_t type);
bool bat_cmp_write_fixext2(bat_cmp_ctx_t *ctx, int8_t type, const void *data);
bool bat_cmp_write_fixext4_marker(bat_cmp_ctx_t *ctx, int8_t type);
bool bat_cmp_write_fixext4(bat_cmp_ctx_t *ctx, int8_t type, const void *data);
bool bat_cmp_write_fixext8_marker(bat_cmp_ctx_t *ctx, int8_t type);
bool bat_cmp_write_fixext8(bat_cmp_ctx_t *ctx, int8_t type, const void *data);
bool bat_cmp_write_fixext16_marker(bat_cmp_ctx_t *ctx, int8_t type);
bool bat_cmp_write_fixext16(bat_cmp_ctx_t *ctx, int8_t type, const void *data);

bool bat_cmp_write_ext8_marker(bat_cmp_ctx_t *ctx, int8_t type, uint8_t size);
bool bat_cmp_write_ext8(bat_cmp_ctx_t *ctx, int8_t type, uint8_t size,
                                    const void *data);
bool bat_cmp_write_ext16_marker(bat_cmp_ctx_t *ctx, int8_t type, uint16_t size);
bool bat_cmp_write_ext16(bat_cmp_ctx_t *ctx, int8_t type, uint16_t size,
                                     const void *data);
bool bat_cmp_write_ext32_marker(bat_cmp_ctx_t *ctx, int8_t type, uint32_t size);
bool bat_cmp_write_ext32(bat_cmp_ctx_t *ctx, int8_t type, uint32_t size,
                                     const void *data);

bool bat_cmp_read_pfix(bat_cmp_ctx_t *ctx, uint8_t *c);
bool bat_cmp_read_nfix(bat_cmp_ctx_t *ctx, int8_t *c);

bool bat_cmp_read_sfix(bat_cmp_ctx_t *ctx, int8_t *c);
bool bat_cmp_read_s8(bat_cmp_ctx_t *ctx, int8_t *c);
bool bat_cmp_read_s16(bat_cmp_ctx_t *ctx, int16_t *s);
bool bat_cmp_read_s32(bat_cmp_ctx_t *ctx, int32_t *i);
bool bat_cmp_read_s64(bat_cmp_ctx_t *ctx, int64_t *l);

bool bat_cmp_read_ufix(bat_cmp_ctx_t *ctx, uint8_t *c);
bool bat_cmp_read_u8(bat_cmp_ctx_t *ctx, uint8_t *c);
bool bat_cmp_read_u16(bat_cmp_ctx_t *ctx, uint16_t *s);
bool bat_cmp_read_u32(bat_cmp_ctx_t *ctx, uint32_t *i);
bool bat_cmp_read_u64(bat_cmp_ctx_t *ctx, uint64_t *l);

bool bat_cmp_read_float(bat_cmp_ctx_t *ctx, float *f);
bool bat_cmp_read_double(bat_cmp_ctx_t *ctx, double *d);

bool bat_cmp_read_fixext1_marker(bat_cmp_ctx_t *ctx, int8_t *type);
bool bat_cmp_read_fixext1(bat_cmp_ctx_t *ctx, int8_t *type, void *data);
bool bat_cmp_read_fixext2_marker(bat_cmp_ctx_t *ctx, int8_t *type);
bool bat_cmp_read_fixext2(bat_cmp_ctx_t *ctx, int8_t *type, void *data);
bool bat_cmp_read_fixext4_marker(bat_cmp_ctx_t *ctx, int8_t *type);
bool bat_cmp_read_fixext4(bat_cmp_ctx_t *ctx, int8_t *type, void *data);
bool bat_cmp_read_fixext8_marker(bat_cmp_ctx_t *ctx, int8_t *type);
bool bat_cmp_read_fixext8(bat_cmp_ctx_t *ctx, int8_t *type, void *data);
bool bat_cmp_read_fixext16_marker(bat_cmp_ctx_t *ctx, int8_t *type);
bool bat_cmp_read_fixext16(bat_cmp_ctx_t *ctx, int8_t *type, void *data);

bool bat_cmp_read_ext8_marker(bat_cmp_ctx_t *ctx, int8_t *type, uint8_t *size);
bool bat_cmp_read_ext8(bat_cmp_ctx_t *ctx, int8_t *type, uint8_t *size, void *data);
bool bat_cmp_read_ext16_marker(bat_cmp_ctx_t *ctx, int8_t *type, uint16_t *size);
bool bat_cmp_read_ext16(bat_cmp_ctx_t *ctx, int8_t *type, uint16_t *size, void *data);
bool bat_cmp_read_ext32_marker(bat_cmp_ctx_t *ctx, int8_t *type, uint32_t *size);
bool bat_cmp_read_ext32(bat_cmp_ctx_t *ctx, int8_t *type, uint32_t *size, void *data);

/*
 * ============================================================================
 * === Object API
 * ============================================================================
 */

bool bat_cmp_object_is_char(bat_cmp_object_t *obj);
bool bat_cmp_object_is_short(bat_cmp_object_t *obj);
bool bat_cmp_object_is_int(bat_cmp_object_t *obj);
bool bat_cmp_object_is_long(bat_cmp_object_t *obj);
bool bat_cmp_object_is_sinteger(bat_cmp_object_t *obj);
bool bat_cmp_object_is_uchar(bat_cmp_object_t *obj);
bool bat_cmp_object_is_ushort(bat_cmp_object_t *obj);
bool bat_cmp_object_is_uint(bat_cmp_object_t *obj);
bool bat_cmp_object_is_ulong(bat_cmp_object_t *obj);
bool bat_cmp_object_is_uinteger(bat_cmp_object_t *obj);
bool bat_cmp_object_is_float(bat_cmp_object_t *obj);
bool bat_cmp_object_is_double(bat_cmp_object_t *obj);
bool bat_cmp_object_is_nil(bat_cmp_object_t *obj);
bool bat_cmp_object_is_bool(bat_cmp_object_t *obj);
bool bat_cmp_object_is_str(bat_cmp_object_t *obj);
bool bat_cmp_object_is_bin(bat_cmp_object_t *obj);
bool bat_cmp_object_is_array(bat_cmp_object_t *obj);
bool bat_cmp_object_is_map(bat_cmp_object_t *obj);
bool bat_cmp_object_is_ext(bat_cmp_object_t *obj);

bool bat_cmp_object_as_char(bat_cmp_object_t *obj, int8_t *c);
bool bat_cmp_object_as_short(bat_cmp_object_t *obj, int16_t *s);
bool bat_cmp_object_as_int(bat_cmp_object_t *obj, int32_t *i);
bool bat_cmp_object_as_long(bat_cmp_object_t *obj, int64_t *d);
bool bat_cmp_object_as_sinteger(bat_cmp_object_t *obj, int64_t *d);
bool bat_cmp_object_as_uchar(bat_cmp_object_t *obj, uint8_t *c);
bool bat_cmp_object_as_ushort(bat_cmp_object_t *obj, uint16_t *s);
bool bat_cmp_object_as_uint(bat_cmp_object_t *obj, uint32_t *i);
bool bat_cmp_object_as_ulong(bat_cmp_object_t *obj, uint64_t *u);
bool bat_cmp_object_as_uinteger(bat_cmp_object_t *obj, uint64_t *u);
bool bat_cmp_object_as_float(bat_cmp_object_t *obj, float *f);
bool bat_cmp_object_as_double(bat_cmp_object_t *obj, double *d);
bool bat_cmp_object_as_bool(bat_cmp_object_t *obj, bool *b);
bool bat_cmp_object_as_str(bat_cmp_object_t *obj, uint32_t *size);
bool bat_cmp_object_as_bin(bat_cmp_object_t *obj, uint32_t *size);
bool bat_cmp_object_as_array(bat_cmp_object_t *obj, uint32_t *size);
bool bat_cmp_object_as_map(bat_cmp_object_t *obj, uint32_t *size);
bool bat_cmp_object_as_ext(bat_cmp_object_t *obj, int8_t *type, uint32_t *size);

bool bat_cmp_object_to_str(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj, char *data, uint32_t buf_size);
bool bat_cmp_object_to_bin(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj, void *data, uint32_t buf_size);

/*
 * ============================================================================
 * === Backwards compatibility defines
 * ============================================================================
 */

#define bat_cmp_write_int      bat_cmp_write_integer
#define bat_cmp_write_sint     bat_cmp_write_integer
#define bat_cmp_write_sinteger bat_cmp_write_integer
#define bat_cmp_write_uint     bat_cmp_write_uinteger
#define bat_cmp_read_sinteger  bat_cmp_read_integer

#endif /* BAT_CMP_H__ */

/* vi: set et ts=2 sw=2: */

