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

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "msgpack-c.h"

static const uint32_t version = 19;
static const uint32_t mp_version = 5;

enum {
  POSITIVE_FIXNUM_MARKER = 0x00,
  FIXMAP_MARKER          = 0x80,
  FIXARRAY_MARKER        = 0x90,
  FIXSTR_MARKER          = 0xA0,
  NIL_MARKER             = 0xC0,
  FALSE_MARKER           = 0xC2,
  TRUE_MARKER            = 0xC3,
  BIN8_MARKER            = 0xC4,
  BIN16_MARKER           = 0xC5,
  BIN32_MARKER           = 0xC6,
  EXT8_MARKER            = 0xC7,
  EXT16_MARKER           = 0xC8,
  EXT32_MARKER           = 0xC9,
  FLOAT_MARKER           = 0xCA,
  DOUBLE_MARKER          = 0xCB,
  U8_MARKER              = 0xCC,
  U16_MARKER             = 0xCD,
  U32_MARKER             = 0xCE,
  U64_MARKER             = 0xCF,
  S8_MARKER              = 0xD0,
  S16_MARKER             = 0xD1,
  S32_MARKER             = 0xD2,
  S64_MARKER             = 0xD3,
  FIXEXT1_MARKER         = 0xD4,
  FIXEXT2_MARKER         = 0xD5,
  FIXEXT4_MARKER         = 0xD6,
  FIXEXT8_MARKER         = 0xD7,
  FIXEXT16_MARKER        = 0xD8,
  STR8_MARKER            = 0xD9,
  STR16_MARKER           = 0xDA,
  STR32_MARKER           = 0xDB,
  ARRAY16_MARKER         = 0xDC,
  ARRAY32_MARKER         = 0xDD,
  MAP16_MARKER           = 0xDE,
  MAP32_MARKER           = 0xDF,
  NEGATIVE_FIXNUM_MARKER = 0xE0
};

enum {
  FIXARRAY_SIZE = 0xF,
  FIXMAP_SIZE   = 0xF,
  FIXSTR_SIZE   = 0x1F
};

const char *bat_cmp_error_messages[BATCMP_ERROR_MAX + 1] = {
  "No Error",
  "Specified string data length is too long (> 0xFFFFFFFF)",
  "Specified binary data length is too long (> 0xFFFFFFFF)",
  "Specified array length is too long (> 0xFFFFFFFF)",
  "Specified map length is too long (> 0xFFFFFFFF)",
  "Input value is too large",
  "Error writing fixed value",
  "Error reading type marker",
  "Error writing type marker",
  "Error reading packed data",
  "Error writing packed data",
  "Error reading ext type",
  "Error writing ext type",
  "Invalid type",
  "Error reading size",
  "Error writing size",
  "Depth limit exceeded while skipping",
  "Internal error",
  "Max Error"
};

static const int32_t _i = 1;
#define is_bigendian() ((*(char *)&_i) == 0)

static uint16_t be16(uint16_t x) {
  char *b = (char *)&x;

  if (!is_bigendian()) {
    char swap = 0;

    swap = b[0];
    b[0] = b[1];
    b[1] = swap;
  }

  return x;
}

static uint32_t be32(uint32_t x) {
  char *b = (char *)&x;

  if (!is_bigendian()) {
    char swap = 0;

    swap = b[0];
    b[0] = b[3];
    b[3] = swap;

    swap = b[1];
    b[1] = b[2];
    b[2] = swap;
  }

  return x;
}

static uint64_t be64(uint64_t x) {
  char *b = (char *)&x;

  if (!is_bigendian()) {
    char swap = 0;

    swap = b[0];
    b[0] = b[7];
    b[7] = swap;

    swap = b[1];
    b[1] = b[6];
    b[6] = swap;

    swap = b[2];
    b[2] = b[5];
    b[5] = swap;

    swap = b[3];
    b[3] = b[4];
    b[4] = swap;
  }

  return x;
}

static float decode_befloat(char *b) {
  float f = 0.;
  char *fb = (char *)&f;

  if (!is_bigendian()) {
    fb[0] = b[3];
    fb[1] = b[2];
    fb[2] = b[1];
    fb[3] = b[0];
  }

  return f;
}

static double decode_bedouble(char *b) {
  double d = 0.;
  char *db = (char *)&d;

  if (!is_bigendian()) {
    db[0] = b[7];
    db[1] = b[6];
    db[2] = b[5];
    db[3] = b[4];
    db[4] = b[3];
    db[5] = b[2];
    db[6] = b[1];
    db[7] = b[0];
  }

  return d;
}

static bool read_byte(bat_cmp_ctx_t *ctx, uint8_t *x) {
  return ctx->read(ctx, x, sizeof(uint8_t));
}

static bool write_byte(bat_cmp_ctx_t *ctx, uint8_t x) {
  return (ctx->write(ctx, &x, sizeof(uint8_t)) == (sizeof(uint8_t)));
}

static bool skip_bytes(bat_cmp_ctx_t *ctx, size_t count) {
  if (ctx->skip) {
    return ctx->skip(ctx, count);
  }
  else {
    uint8_t floor;
    size_t i;

    for (i = 0; i < count; i++) {
      if (!ctx->read(ctx, &floor, sizeof(uint8_t))) {
        return false;
      }
    }

    return true;
  }
}

static bool read_type_marker(bat_cmp_ctx_t *ctx, uint8_t *marker) {
  if (read_byte(ctx, marker)) {
    return true;
  }

  ctx->error = BATCMP_TYPE_MARKER_READING_ERROR;
  return false;
}

static bool write_type_marker(bat_cmp_ctx_t *ctx, uint8_t marker) {
  if (write_byte(ctx, marker))
    return true;

  ctx->error = BATCMP_TYPE_MARKER_WRITING_ERROR;
  return false;
}

static bool write_fixed_value(bat_cmp_ctx_t *ctx, uint8_t value) {
  if (write_byte(ctx, value))
    return true;

  ctx->error = BATCMP_FIXED_VALUE_WRITING_ERROR;
  return false;
}

static bool type_marker_to_bat_cmp_type(uint8_t type_marker, uint8_t *bat_cmp_type) {
  if (type_marker <= 0x7F) {
    *bat_cmp_type = BAT_CMP_TYPE_POSITIVE_FIXNUM;
    return true;
  }

  if (type_marker <= 0x8F) {
    *bat_cmp_type = BAT_CMP_TYPE_FIXMAP;
    return true;
  }

  if (type_marker <= 0x9F) {
    *bat_cmp_type = BAT_CMP_TYPE_FIXARRAY;
    return true;
  }

  if (type_marker <= 0xBF) {
    *bat_cmp_type = BAT_CMP_TYPE_FIXSTR;
    return true;
  }

  if (type_marker >= 0xE0) {
    *bat_cmp_type = BAT_CMP_TYPE_NEGATIVE_FIXNUM;
    return true;
  }

  switch (type_marker) {
    case NIL_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_NIL;
      return true;
    case FALSE_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_BOOLEAN;
      return true;
    case TRUE_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_BOOLEAN;
      return true;
    case BIN8_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_BIN8;
      return true;
    case BIN16_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_BIN16;
      return true;
    case BIN32_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_BIN32;
      return true;
    case EXT8_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_EXT8;
      return true;
    case EXT16_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_EXT16;
      return true;
    case EXT32_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_EXT32;
      return true;
    case FLOAT_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_FLOAT;
      return true;
    case DOUBLE_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_DOUBLE;
      return true;
    case U8_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_UINT8;
      return true;
    case U16_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_UINT16;
      return true;
    case U32_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_UINT32;
      return true;
    case U64_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_UINT64;
      return true;
    case S8_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_SINT8;
      return true;
    case S16_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_SINT16;
      return true;
    case S32_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_SINT32;
      return true;
    case S64_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_SINT64;
      return true;
    case FIXEXT1_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_FIXEXT1;
      return true;
    case FIXEXT2_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_FIXEXT2;
      return true;
    case FIXEXT4_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_FIXEXT4;
      return true;
    case FIXEXT8_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_FIXEXT8;
      return true;
    case FIXEXT16_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_FIXEXT16;
      return true;
    case STR8_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_STR8;
      return true;
    case STR16_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_STR16;
      return true;
    case STR32_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_STR32;
      return true;
    case ARRAY16_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_ARRAY16;
      return true;
    case ARRAY32_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_ARRAY32;
      return true;
    case MAP16_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_MAP16;
      return true;
    case MAP32_MARKER:
      *bat_cmp_type = BAT_CMP_TYPE_MAP32;
      return true;
    default:
      return false;
  }
}

static bool read_type_size(bat_cmp_ctx_t *ctx, uint8_t type_marker,
                                           uint8_t bat_cmp_type,
                                           uint32_t *size) {
  uint8_t u8temp = 0;
  uint16_t u16temp = 0;
  uint32_t u32temp = 0;

  switch (bat_cmp_type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
      *size = 0;
      return true;
    case BAT_CMP_TYPE_FIXMAP:
      *size = (type_marker & FIXMAP_SIZE);
      return true;
    case BAT_CMP_TYPE_FIXARRAY:
      *size = (type_marker & FIXARRAY_SIZE);
      return true;
    case BAT_CMP_TYPE_FIXSTR:
      *size = (type_marker & FIXSTR_SIZE);
      return true;
    case BAT_CMP_TYPE_NIL:
      *size = 0;
      return true;
    case BAT_CMP_TYPE_BOOLEAN:
      *size = 0;
      return true;
    case BAT_CMP_TYPE_BIN8:
      if (!ctx->read(ctx, &u8temp, sizeof(uint8_t))) {
        ctx->error = BATCMP_LENGTH_READING_ERROR;
        return false;
      }
      *size = u8temp;
      return true;
    case BAT_CMP_TYPE_BIN16:
      if (!ctx->read(ctx, &u16temp, sizeof(uint16_t))) {
        ctx->error = BATCMP_LENGTH_READING_ERROR;
        return false;
      }
      *size = be16(u16temp);
      return true;
    case BAT_CMP_TYPE_BIN32:
      if (!ctx->read(ctx, &u32temp, sizeof(uint32_t))) {
        ctx->error = BATCMP_LENGTH_READING_ERROR;
        return false;
      }
      *size = be32(u32temp);
      return true;
    case BAT_CMP_TYPE_EXT8:
      if (!ctx->read(ctx, &u8temp, sizeof(uint8_t))) {
        ctx->error = BATCMP_LENGTH_READING_ERROR;
        return false;
      }
      *size = u8temp;
      return true;
    case BAT_CMP_TYPE_EXT16:
      if (!ctx->read(ctx, &u16temp, sizeof(uint16_t))) {
        ctx->error = BATCMP_LENGTH_READING_ERROR;
        return false;
      }
      *size = be16(u16temp);
      return true;
    case BAT_CMP_TYPE_EXT32:
      if (!ctx->read(ctx, &u32temp, sizeof(uint32_t))) {
        ctx->error = BATCMP_LENGTH_READING_ERROR;
        return false;
      }
      *size = be32(u32temp);
      return true;
    case BAT_CMP_TYPE_FLOAT:
      *size = 4;
      return true;
    case BAT_CMP_TYPE_DOUBLE:
      *size = 8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      *size = 1;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *size = 2;
      return true;
    case BAT_CMP_TYPE_UINT32:
      *size = 4;
      return true;
    case BAT_CMP_TYPE_UINT64:
      *size = 8;
      return true;
    case BAT_CMP_TYPE_SINT8:
      *size = 1;
      return true;
    case BAT_CMP_TYPE_SINT16:
      *size = 2;
      return true;
    case BAT_CMP_TYPE_SINT32:
      *size = 4;
      return true;
    case BAT_CMP_TYPE_SINT64:
      *size = 8;
      return true;
    case BAT_CMP_TYPE_FIXEXT1:
      *size = 1;
      return true;
    case BAT_CMP_TYPE_FIXEXT2:
      *size = 2;
      return true;
    case BAT_CMP_TYPE_FIXEXT4:
      *size = 4;
      return true;
    case BAT_CMP_TYPE_FIXEXT8:
      *size = 8;
      return true;
    case BAT_CMP_TYPE_FIXEXT16:
      *size = 16;
      return true;
    case BAT_CMP_TYPE_STR8:
      if (!ctx->read(ctx, &u8temp, sizeof(uint8_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      *size = u8temp;
      return true;
    case BAT_CMP_TYPE_STR16:
      if (!ctx->read(ctx, &u16temp, sizeof(uint16_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      *size = be16(u16temp);
      return true;
    case BAT_CMP_TYPE_STR32:
      if (!ctx->read(ctx, &u32temp, sizeof(uint32_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      *size = be32(u32temp);
      return true;
    case BAT_CMP_TYPE_ARRAY16:
      if (!ctx->read(ctx, &u16temp, sizeof(uint16_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      *size = be16(u16temp);
      return true;
    case BAT_CMP_TYPE_ARRAY32:
      if (!ctx->read(ctx, &u32temp, sizeof(uint32_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      *size = be32(u32temp);
      return true;
    case BAT_CMP_TYPE_MAP16:
      if (!ctx->read(ctx, &u16temp, sizeof(uint16_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      *size = be16(u16temp);
      return true;
    case BAT_CMP_TYPE_MAP32:
      if (!ctx->read(ctx, &u32temp, sizeof(uint32_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      *size = be32(u32temp);
      return true;
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
      *size = 0;
      return true;
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

static bool read_obj_data(bat_cmp_ctx_t *ctx, uint8_t type_marker,
                                          bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
      obj->as.u8 = type_marker;
      return true;
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
      obj->as.s8 = type_marker;
      return true;
    case BAT_CMP_TYPE_NIL:
      obj->as.u8 = 0;
      return true;
    case BAT_CMP_TYPE_BOOLEAN:
      switch (type_marker) {
        case TRUE_MARKER:
          obj->as.boolean = true;
          return true;
        case FALSE_MARKER:
          obj->as.boolean = false;
          return true;
        default:
          break;
      }
      ctx->error = BATCMP_INTERNAL_ERROR;
      return false;
    case BAT_CMP_TYPE_UINT8:
      if (!ctx->read(ctx, &obj->as.u8, sizeof(uint8_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      return true;
    case BAT_CMP_TYPE_UINT16:
      if (!ctx->read(ctx, &obj->as.u16, sizeof(uint16_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      obj->as.u16 = be16(obj->as.u16);
      return true;
    case BAT_CMP_TYPE_UINT32:
      if (!ctx->read(ctx, &obj->as.u32, sizeof(uint32_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      obj->as.u32 = be32(obj->as.u32);
      return true;
    case BAT_CMP_TYPE_UINT64:
      if (!ctx->read(ctx, &obj->as.u64, sizeof(uint64_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      obj->as.u64 = be64(obj->as.u64);
      return true;
    case BAT_CMP_TYPE_SINT8:
      if (!ctx->read(ctx, &obj->as.s8, sizeof(int8_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      return true;
    case BAT_CMP_TYPE_SINT16:
      if (!ctx->read(ctx, &obj->as.s16, sizeof(int16_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      obj->as.s16 = be16(obj->as.s16);
      return true;
    case BAT_CMP_TYPE_SINT32:
      if (!ctx->read(ctx, &obj->as.s32, sizeof(int32_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      obj->as.s32 = be32(obj->as.s32);
      return true;
    case BAT_CMP_TYPE_SINT64:
      if (!ctx->read(ctx, &obj->as.s64, sizeof(int64_t))) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      obj->as.s64 = be64(obj->as.s64);
      return true;
    case BAT_CMP_TYPE_FLOAT:
    {
      char bytes[4];

      if (!ctx->read(ctx, bytes, 4)) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      obj->as.flt = decode_befloat(bytes);
      return true;
    }
    case BAT_CMP_TYPE_DOUBLE:
    {
      char bytes[8];

      if (!ctx->read(ctx, bytes, 8)) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      obj->as.dbl = decode_bedouble(bytes);
      return true;
    }
    case BAT_CMP_TYPE_BIN8:
    case BAT_CMP_TYPE_BIN16:
    case BAT_CMP_TYPE_BIN32:
      return read_type_size(ctx, type_marker, obj->type, &obj->as.bin_size);
    case BAT_CMP_TYPE_FIXSTR:
    case BAT_CMP_TYPE_STR8:
    case BAT_CMP_TYPE_STR16:
    case BAT_CMP_TYPE_STR32:
      return read_type_size(ctx, type_marker, obj->type, &obj->as.str_size);
    case BAT_CMP_TYPE_FIXARRAY:
    case BAT_CMP_TYPE_ARRAY16:
    case BAT_CMP_TYPE_ARRAY32:
      return read_type_size(ctx, type_marker, obj->type, &obj->as.array_size);
    case BAT_CMP_TYPE_FIXMAP:
    case BAT_CMP_TYPE_MAP16:
    case BAT_CMP_TYPE_MAP32:
      return read_type_size(ctx, type_marker, obj->type, &obj->as.map_size);
    case BAT_CMP_TYPE_FIXEXT1:
      if (!ctx->read(ctx, &obj->as.ext.type, sizeof(int8_t))) {
        ctx->error = BATCMP_EXT_TYPE_READING_ERROR;
        return false;
      }
      obj->as.ext.size = 1;
      return true;
    case BAT_CMP_TYPE_FIXEXT2:
      if (!ctx->read(ctx, &obj->as.ext.type, sizeof(int8_t))) {
        ctx->error = BATCMP_EXT_TYPE_READING_ERROR;
        return false;
      }
      obj->as.ext.size = 2;
      return true;
    case BAT_CMP_TYPE_FIXEXT4:
      if (!ctx->read(ctx, &obj->as.ext.type, sizeof(int8_t))) {
        ctx->error = BATCMP_EXT_TYPE_READING_ERROR;
        return false;
      }
      obj->as.ext.size = 4;
      return true;
    case BAT_CMP_TYPE_FIXEXT8:
      if (!ctx->read(ctx, &obj->as.ext.type, sizeof(int8_t))) {
        ctx->error = BATCMP_EXT_TYPE_READING_ERROR;
        return false;
      }
      obj->as.ext.size = 8;
      return true;
    case BAT_CMP_TYPE_FIXEXT16:
      if (!ctx->read(ctx, &obj->as.ext.type, sizeof(int8_t))) {
        ctx->error = BATCMP_EXT_TYPE_READING_ERROR;
        return false;
      }
      obj->as.ext.size = 16;
      return true;
    case BAT_CMP_TYPE_EXT8:
      if (!read_type_size(ctx, type_marker, obj->type, &obj->as.ext.size)) {
        return false;
      }
      if (!ctx->read(ctx, &obj->as.ext.type, sizeof(int8_t))) {
        ctx->error = BATCMP_EXT_TYPE_READING_ERROR;
        return false;
      }
      return true;
    case BAT_CMP_TYPE_EXT16:
      if (!read_type_size(ctx, type_marker, obj->type, &obj->as.ext.size)) {
        return false;
      }
      if (!ctx->read(ctx, &obj->as.ext.type, sizeof(int8_t))) {
        ctx->error = BATCMP_EXT_TYPE_READING_ERROR;
        return false;
      }
      obj->as.ext.type = obj->as.ext.type;
      return true;
    case BAT_CMP_TYPE_EXT32:
      if (!read_type_size(ctx, type_marker, obj->type, &obj->as.ext.size)) {
        return false;
      }
      if (!ctx->read(ctx, &obj->as.ext.type, sizeof(int8_t))) {
        ctx->error = BATCMP_EXT_TYPE_READING_ERROR;
        return false;
      }
      obj->as.ext.type = obj->as.ext.type;
      return true;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

void bat_cmp_init(bat_cmp_ctx_t *ctx, void *buf, bat_cmp_reader read,
                                         bat_cmp_skipper skip,
                                         bat_cmp_writer write) {
  ctx->error = BATCMP_ERROR_NONE;
  ctx->buf = buf;
  ctx->read = read;
  ctx->skip = skip;
  ctx->write = write;
}

uint32_t bat_cmp_version(void) {
  return version;
}

uint32_t bat_cmp_mp_version(void) {
  return mp_version;
}

const char* bat_cmp_strerror(bat_cmp_ctx_t *ctx) {
  if (ctx->error > BATCMP_ERROR_NONE && ctx->error < BATCMP_ERROR_MAX)
    return bat_cmp_error_messages[ctx->error];

  return "";
}

bool bat_cmp_write_pfix(bat_cmp_ctx_t *ctx, uint8_t c) {
  if (c <= 0x7F)
    return write_fixed_value(ctx, c);

  ctx->error = BATCMP_INPUT_VALUE_TOO_LARGE_ERROR;
  return false;
}

bool bat_cmp_write_nfix(bat_cmp_ctx_t *ctx, int8_t c) {
  if (c >= -32 && c <= -1)
    return write_fixed_value(ctx, c);

  ctx->error = BATCMP_INPUT_VALUE_TOO_LARGE_ERROR;
  return false;
}

bool bat_cmp_write_sfix(bat_cmp_ctx_t *ctx, int8_t c) {
  if (c >= 0)
    return bat_cmp_write_pfix(ctx, c);
  if (c >= -32 && c <= -1)
    return bat_cmp_write_nfix(ctx, c);

  ctx->error = BATCMP_INPUT_VALUE_TOO_LARGE_ERROR;
  return false;
}

bool bat_cmp_write_s8(bat_cmp_ctx_t *ctx, int8_t c) {
  if (!write_type_marker(ctx, S8_MARKER))
    return false;

  return ctx->write(ctx, &c, sizeof(int8_t));
}

bool bat_cmp_write_s16(bat_cmp_ctx_t *ctx, int16_t s) {
  if (!write_type_marker(ctx, S16_MARKER))
    return false;

  s = be16(s);

  return ctx->write(ctx, &s, sizeof(int16_t));
}

bool bat_cmp_write_s32(bat_cmp_ctx_t *ctx, int32_t i) {
  if (!write_type_marker(ctx, S32_MARKER))
    return false;

  i = be32(i);

  return ctx->write(ctx, &i, sizeof(int32_t));
}

bool bat_cmp_write_s64(bat_cmp_ctx_t *ctx, int64_t l) {
  if (!write_type_marker(ctx, S64_MARKER))
    return false;

  l = be64(l);

  return ctx->write(ctx, &l, sizeof(int64_t));
}

bool bat_cmp_write_integer(bat_cmp_ctx_t *ctx, int64_t d) {
  if (d >= 0)
    return bat_cmp_write_uinteger(ctx, d);
  if (d >= -32)
    return bat_cmp_write_nfix(ctx, (int8_t)d);
  if (d >= -128)
    return bat_cmp_write_s8(ctx, (int8_t)d);
  if (d >= -32768)
    return bat_cmp_write_s16(ctx, (int16_t)d);
  if (d >= (-2147483647 - 1))
    return bat_cmp_write_s32(ctx, (int32_t)d);

  return bat_cmp_write_s64(ctx, d);
}

bool bat_cmp_write_ufix(bat_cmp_ctx_t *ctx, uint8_t c) {
  return bat_cmp_write_pfix(ctx, c);
}

bool bat_cmp_write_u8(bat_cmp_ctx_t *ctx, uint8_t c) {
  if (!write_type_marker(ctx, U8_MARKER))
    return false;

  return ctx->write(ctx, &c, sizeof(uint8_t));
}

bool bat_cmp_write_u16(bat_cmp_ctx_t *ctx, uint16_t s) {
  if (!write_type_marker(ctx, U16_MARKER))
    return false;

  s = be16(s);

  return ctx->write(ctx, &s, sizeof(uint16_t));
}

bool bat_cmp_write_u32(bat_cmp_ctx_t *ctx, uint32_t i) {
  if (!write_type_marker(ctx, U32_MARKER))
    return false;

  i = be32(i);

  return ctx->write(ctx, &i, sizeof(uint32_t));
}

bool bat_cmp_write_u64(bat_cmp_ctx_t *ctx, uint64_t l) {
  if (!write_type_marker(ctx, U64_MARKER))
    return false;

  l = be64(l);

  return ctx->write(ctx, &l, sizeof(uint64_t));
}

bool bat_cmp_write_uinteger(bat_cmp_ctx_t *ctx, uint64_t u) {
  if (u <= 0x7F)
    return bat_cmp_write_pfix(ctx, (uint8_t)u);
  if (u <= 0xFF)
    return bat_cmp_write_u8(ctx, (uint8_t)u);
  if (u <= 0xFFFF)
    return bat_cmp_write_u16(ctx, (uint16_t)u);
  if (u <= 0xFFFFFFFF)
    return bat_cmp_write_u32(ctx, (uint32_t)u);

  return bat_cmp_write_u64(ctx, u);
}

bool bat_cmp_write_float(bat_cmp_ctx_t *ctx, float f) {
  if (!write_type_marker(ctx, FLOAT_MARKER))
    return false;

  /*
   * We may need to swap the float's bytes, but we can't just swap them inside
   * the float because the swapped bytes may not constitute a valid float.
   * Therefore, we have to create a buffer and swap the bytes there.
   */
  if (!is_bigendian()) {
    char swapped[sizeof(float)];
    char *fbuf = (char *)&f;
    size_t i;

    for (i = 0; i < sizeof(float); i++)
      swapped[i] = fbuf[sizeof(float) - i - 1];

    return ctx->write(ctx, swapped, sizeof(float));
  }

  return ctx->write(ctx, &f, sizeof(float));
}

bool bat_cmp_write_double(bat_cmp_ctx_t *ctx, double d) {
  if (!write_type_marker(ctx, DOUBLE_MARKER))
    return false;

  /* Same deal for doubles */
  if (!is_bigendian()) {
    char swapped[sizeof(double)];
    char *dbuf = (char *)&d;
    size_t i;

    for (i = 0; i < sizeof(double); i++)
      swapped[i] = dbuf[sizeof(double) - i - 1];

    return ctx->write(ctx, swapped, sizeof(double));
  }

  return ctx->write(ctx, &d, sizeof(double));
}

bool bat_cmp_write_decimal(bat_cmp_ctx_t *ctx, double d) {
  float f = (float)d;
  double df = (double)f;

  if (df == d)
    return bat_cmp_write_float(ctx, f);
  else
    return bat_cmp_write_double(ctx, d);
}

bool bat_cmp_write_nil(bat_cmp_ctx_t *ctx) {
  return write_type_marker(ctx, NIL_MARKER);
}

bool bat_cmp_write_true(bat_cmp_ctx_t *ctx) {
  return write_type_marker(ctx, TRUE_MARKER);
}

bool bat_cmp_write_false(bat_cmp_ctx_t *ctx) {
  return write_type_marker(ctx, FALSE_MARKER);
}

bool bat_cmp_write_bool(bat_cmp_ctx_t *ctx, bool b) {
  if (b)
    return bat_cmp_write_true(ctx);

  return bat_cmp_write_false(ctx);
}

bool bat_cmp_write_u8_as_bool(bat_cmp_ctx_t *ctx, uint8_t b) {
  if (b)
    return bat_cmp_write_true(ctx);

  return bat_cmp_write_false(ctx);
}

bool bat_cmp_write_fixstr_marker(bat_cmp_ctx_t *ctx, uint8_t size) {
  if (size <= FIXSTR_SIZE)
    return write_fixed_value(ctx, FIXSTR_MARKER | size);

  ctx->error = BATCMP_INPUT_VALUE_TOO_LARGE_ERROR;
  return false;
}

bool bat_cmp_write_fixstr(bat_cmp_ctx_t *ctx, const char *data, uint8_t size) {
  if (!bat_cmp_write_fixstr_marker(ctx, size))
    return false;

  if (size == 0)
    return true;

  if (ctx->write(ctx, data, size))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_str8_marker(bat_cmp_ctx_t *ctx, uint8_t size) {
  if (!write_type_marker(ctx, STR8_MARKER))
    return false;

  if (ctx->write(ctx, &size, sizeof(uint8_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_str8(bat_cmp_ctx_t *ctx, const char *data, uint8_t size) {
  if (!bat_cmp_write_str8_marker(ctx, size))
    return false;

  if (size == 0)
    return true;

  if (ctx->write(ctx, data, size))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_str16_marker(bat_cmp_ctx_t *ctx, uint16_t size) {
  if (!write_type_marker(ctx, STR16_MARKER))
    return false;

  size = be16(size);

  if (ctx->write(ctx, &size, sizeof(uint16_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_str16(bat_cmp_ctx_t *ctx, const char *data, uint16_t size) {
  if (!bat_cmp_write_str16_marker(ctx, size))
    return false;

  if (size == 0)
    return true;

  if (ctx->write(ctx, data, size))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_str32_marker(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (!write_type_marker(ctx, STR32_MARKER))
    return false;

  size = be32(size);

  if (ctx->write(ctx, &size, sizeof(uint32_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_str32(bat_cmp_ctx_t *ctx, const char *data, uint32_t size) {
  if (!bat_cmp_write_str32_marker(ctx, size))
    return false;

  if (size == 0)
    return true;

  if (ctx->write(ctx, data, size))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_str_marker(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (size <= FIXSTR_SIZE)
    return bat_cmp_write_fixstr_marker(ctx, (uint8_t)size);
  if (size <= 0xFF)
    return bat_cmp_write_str8_marker(ctx, (uint8_t)size);
  if (size <= 0xFFFF)
    return bat_cmp_write_str16_marker(ctx, (uint16_t)size);

  return bat_cmp_write_str32_marker(ctx, size);
}

bool bat_cmp_write_str_marker_v4(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (size <= FIXSTR_SIZE)
    return bat_cmp_write_fixstr_marker(ctx, (uint8_t)size);
  if (size <= 0xFFFF)
    return bat_cmp_write_str16_marker(ctx, (uint16_t)size);

  return bat_cmp_write_str32_marker(ctx, size);
}

bool bat_cmp_write_str(bat_cmp_ctx_t *ctx, const char *data, uint32_t size) {
  if (size <= FIXSTR_SIZE)
    return bat_cmp_write_fixstr(ctx, data, (uint8_t)size);
  if (size <= 0xFF)
    return bat_cmp_write_str8(ctx, data, (uint8_t)size);
  if (size <= 0xFFFF)
    return bat_cmp_write_str16(ctx, data, (uint16_t)size);

  return bat_cmp_write_str32(ctx, data, size);
}

bool bat_cmp_write_str_v4(bat_cmp_ctx_t *ctx, const char *data, uint32_t size) {
  if (size <= FIXSTR_SIZE)
    return bat_cmp_write_fixstr(ctx, data, (uint8_t)size);
  if (size <= 0xFFFF)
    return bat_cmp_write_str16(ctx, data, (uint16_t)size);

  return bat_cmp_write_str32(ctx, data, size);
}

bool bat_cmp_write_bin8_marker(bat_cmp_ctx_t *ctx, uint8_t size) {
  if (!write_type_marker(ctx, BIN8_MARKER))
    return false;

  if (ctx->write(ctx, &size, sizeof(uint8_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_bin8(bat_cmp_ctx_t *ctx, const void *data, uint8_t size) {
  if (!bat_cmp_write_bin8_marker(ctx, size))
    return false;

  if (size == 0)
    return true;

  if (ctx->write(ctx, data, size))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_bin16_marker(bat_cmp_ctx_t *ctx, uint16_t size) {
  if (!write_type_marker(ctx, BIN16_MARKER))
    return false;

  size = be16(size);

  if (ctx->write(ctx, &size, sizeof(uint16_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_bin16(bat_cmp_ctx_t *ctx, const void *data, uint16_t size) {
  if (!bat_cmp_write_bin16_marker(ctx, size))
    return false;

  if (size == 0)
    return true;

  if (ctx->write(ctx, data, size))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_bin32_marker(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (!write_type_marker(ctx, BIN32_MARKER))
    return false;

  size = be32(size);

  if (ctx->write(ctx, &size, sizeof(uint32_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_bin32(bat_cmp_ctx_t *ctx, const void *data, uint32_t size) {
  if (!bat_cmp_write_bin32_marker(ctx, size))
    return false;

  if (size == 0)
    return true;

  if (ctx->write(ctx, data, size))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_bin_marker(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (size <= 0xFF)
    return bat_cmp_write_bin8_marker(ctx, (uint8_t)size);
  if (size <= 0xFFFF)
    return bat_cmp_write_bin16_marker(ctx, (uint16_t)size);

  return bat_cmp_write_bin32_marker(ctx, size);
}

bool bat_cmp_write_bin(bat_cmp_ctx_t *ctx, const void *data, uint32_t size) {
  if (size <= 0xFF)
    return bat_cmp_write_bin8(ctx, data, (uint8_t)size);
  if (size <= 0xFFFF)
    return bat_cmp_write_bin16(ctx, data, (uint16_t)size);

  return bat_cmp_write_bin32(ctx, data, size);
}

bool bat_cmp_write_fixarray(bat_cmp_ctx_t *ctx, uint8_t size) {
  if (size <= FIXARRAY_SIZE)
    return write_fixed_value(ctx, FIXARRAY_MARKER | size);

  ctx->error = BATCMP_INPUT_VALUE_TOO_LARGE_ERROR;
  return false;
}

bool bat_cmp_write_array16(bat_cmp_ctx_t *ctx, uint16_t size) {
  if (!write_type_marker(ctx, ARRAY16_MARKER))
    return false;

  size = be16(size);

  if (ctx->write(ctx, &size, sizeof(uint16_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_array32(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (!write_type_marker(ctx, ARRAY32_MARKER))
    return false;

  size = be32(size);

  if (ctx->write(ctx, &size, sizeof(uint32_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_array(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (size <= FIXARRAY_SIZE)
    return bat_cmp_write_fixarray(ctx, (uint8_t)size);
  if (size <= 0xFFFF)
    return bat_cmp_write_array16(ctx, (uint16_t)size);

  return bat_cmp_write_array32(ctx, size);
}

bool bat_cmp_write_fixmap(bat_cmp_ctx_t *ctx, uint8_t size) {
  if (size <= FIXMAP_SIZE)
    return write_fixed_value(ctx, FIXMAP_MARKER | size);

  ctx->error = BATCMP_INPUT_VALUE_TOO_LARGE_ERROR;
  return false;
}

bool bat_cmp_write_map16(bat_cmp_ctx_t *ctx, uint16_t size) {
  if (!write_type_marker(ctx, MAP16_MARKER))
    return false;

  size = be16(size);

  if (ctx->write(ctx, &size, sizeof(uint16_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_map32(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (!write_type_marker(ctx, MAP32_MARKER))
    return false;

  size = be32(size);

  if (ctx->write(ctx, &size, sizeof(uint32_t)))
    return true;

  ctx->error = BATCMP_LENGTH_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_map(bat_cmp_ctx_t *ctx, uint32_t size) {
  if (size <= FIXMAP_SIZE)
    return bat_cmp_write_fixmap(ctx, (uint8_t)size);
  if (size <= 0xFFFF)
    return bat_cmp_write_map16(ctx, (uint16_t)size);

  return bat_cmp_write_map32(ctx, size);
}

bool bat_cmp_write_fixext1_marker(bat_cmp_ctx_t *ctx, int8_t type) {
  if (!write_type_marker(ctx, FIXEXT1_MARKER))
    return false;

  if (ctx->write(ctx, &type, sizeof(int8_t)))
    return true;

  ctx->error = BATCMP_EXT_TYPE_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext1(bat_cmp_ctx_t *ctx, int8_t type, const void *data) {
  if (!bat_cmp_write_fixext1_marker(ctx, type))
    return false;

  if (ctx->write(ctx, data, 1))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext2_marker(bat_cmp_ctx_t *ctx, int8_t type) {
  if (!write_type_marker(ctx, FIXEXT2_MARKER))
    return false;

  if (ctx->write(ctx, &type, sizeof(int8_t)))
    return true;

  ctx->error = BATCMP_EXT_TYPE_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext2(bat_cmp_ctx_t *ctx, int8_t type, const void *data) {
  if (!bat_cmp_write_fixext2_marker(ctx, type))
    return false;

  if (ctx->write(ctx, data, 2))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext4_marker(bat_cmp_ctx_t *ctx, int8_t type) {
  if (!write_type_marker(ctx, FIXEXT4_MARKER))
    return false;

  if (ctx->write(ctx, &type, sizeof(int8_t)))
    return true;

  ctx->error = BATCMP_EXT_TYPE_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext4(bat_cmp_ctx_t *ctx, int8_t type, const void *data) {
  if (!bat_cmp_write_fixext4_marker(ctx, type))
    return false;

  if (ctx->write(ctx, data, 4))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext8_marker(bat_cmp_ctx_t *ctx, int8_t type) {
  if (!write_type_marker(ctx, FIXEXT8_MARKER))
    return false;

  if (ctx->write(ctx, &type, sizeof(int8_t)))
    return true;

  ctx->error = BATCMP_EXT_TYPE_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext8(bat_cmp_ctx_t *ctx, int8_t type, const void *data) {
  if (!bat_cmp_write_fixext8_marker(ctx, type))
    return false;

  if (ctx->write(ctx, data, 8))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext16_marker(bat_cmp_ctx_t *ctx, int8_t type) {
  if (!write_type_marker(ctx, FIXEXT16_MARKER))
    return false;

  if (ctx->write(ctx, &type, sizeof(int8_t)))
    return true;

  ctx->error = BATCMP_EXT_TYPE_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_fixext16(bat_cmp_ctx_t *ctx, int8_t type, const void *data) {
  if (!bat_cmp_write_fixext16_marker(ctx, type))
    return false;

  if (ctx->write(ctx, data, 16))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_ext8_marker(bat_cmp_ctx_t *ctx, int8_t type, uint8_t size) {
  if (!write_type_marker(ctx, EXT8_MARKER))
    return false;

  if (!ctx->write(ctx, &size, sizeof(uint8_t))) {
    ctx->error = BATCMP_LENGTH_WRITING_ERROR;
    return false;
  }

  if (ctx->write(ctx, &type, sizeof(int8_t)))
    return true;

  ctx->error = BATCMP_EXT_TYPE_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_ext8(bat_cmp_ctx_t *ctx, int8_t tp, uint8_t sz, const void *data) {
  if (!bat_cmp_write_ext8_marker(ctx, tp, sz))
    return false;

  if (ctx->write(ctx, data, sz))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_ext16_marker(bat_cmp_ctx_t *ctx, int8_t type, uint16_t size) {
  if (!write_type_marker(ctx, EXT16_MARKER))
    return false;

  size = be16(size);

  if (!ctx->write(ctx, &size, sizeof(uint16_t))) {
    ctx->error = BATCMP_LENGTH_WRITING_ERROR;
    return false;
  }

  if (ctx->write(ctx, &type, sizeof(int8_t)))
    return true;

  ctx->error = BATCMP_EXT_TYPE_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_ext16(bat_cmp_ctx_t *ctx, int8_t tp, uint16_t sz, const void *data) {
  if (!bat_cmp_write_ext16_marker(ctx, tp, sz))
    return false;

  if (ctx->write(ctx, data, sz))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_ext32_marker(bat_cmp_ctx_t *ctx, int8_t type, uint32_t size) {
  if (!write_type_marker(ctx, EXT32_MARKER))
    return false;

  size = be32(size);

  if (!ctx->write(ctx, &size, sizeof(uint32_t))) {
    ctx->error = BATCMP_LENGTH_WRITING_ERROR;
    return false;
  }

  if (ctx->write(ctx, &type, sizeof(int8_t)))
    return true;

  ctx->error = BATCMP_EXT_TYPE_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_ext32(bat_cmp_ctx_t *ctx, int8_t tp, uint32_t sz, const void *data) {
  if (!bat_cmp_write_ext32_marker(ctx, tp, sz))
    return false;

  if (ctx->write(ctx, data, sz))
    return true;

  ctx->error = BATCMP_DATA_WRITING_ERROR;
  return false;
}

bool bat_cmp_write_ext_marker(bat_cmp_ctx_t *ctx, int8_t tp, uint32_t sz) {
  if (sz == 1)
    return bat_cmp_write_fixext1_marker(ctx, tp);
  if (sz == 2)
    return bat_cmp_write_fixext2_marker(ctx, tp);
  if (sz == 4)
    return bat_cmp_write_fixext4_marker(ctx, tp);
  if (sz == 8)
    return bat_cmp_write_fixext8_marker(ctx, tp);
  if (sz == 16)
    return bat_cmp_write_fixext16_marker(ctx, tp);
  if (sz <= 0xFF)
    return bat_cmp_write_ext8_marker(ctx, tp, (uint8_t)sz);
  if (sz <= 0xFFFF)
    return bat_cmp_write_ext16_marker(ctx, tp, (uint16_t)sz);

  return bat_cmp_write_ext32_marker(ctx, tp, sz);
}

bool bat_cmp_write_ext(bat_cmp_ctx_t *ctx, int8_t tp, uint32_t sz, const void *data) {
  if (sz == 1)
    return bat_cmp_write_fixext1(ctx, tp, data);
  if (sz == 2)
    return bat_cmp_write_fixext2(ctx, tp, data);
  if (sz == 4)
    return bat_cmp_write_fixext4(ctx, tp, data);
  if (sz == 8)
    return bat_cmp_write_fixext8(ctx, tp, data);
  if (sz == 16)
    return bat_cmp_write_fixext16(ctx, tp, data);
  if (sz <= 0xFF)
    return bat_cmp_write_ext8(ctx, tp, (uint8_t)sz, data);
  if (sz <= 0xFFFF)
    return bat_cmp_write_ext16(ctx, tp, (uint16_t)sz, data);

  return bat_cmp_write_ext32(ctx, tp, sz, data);
}

bool bat_cmp_write_object(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj) {
  switch(obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
      return bat_cmp_write_pfix(ctx, obj->as.u8);
    case BAT_CMP_TYPE_FIXMAP:
      return bat_cmp_write_fixmap(ctx, (uint8_t)obj->as.map_size);
    case BAT_CMP_TYPE_FIXARRAY:
      return bat_cmp_write_fixarray(ctx, (uint8_t)obj->as.array_size);
    case BAT_CMP_TYPE_FIXSTR:
      return bat_cmp_write_fixstr_marker(ctx, (uint8_t)obj->as.str_size);
    case BAT_CMP_TYPE_NIL:
      return bat_cmp_write_nil(ctx);
    case BAT_CMP_TYPE_BOOLEAN:
      if (obj->as.boolean)
        return bat_cmp_write_true(ctx);
      return bat_cmp_write_false(ctx);
    case BAT_CMP_TYPE_BIN8:
      return bat_cmp_write_bin8_marker(ctx, (uint8_t)obj->as.bin_size);
    case BAT_CMP_TYPE_BIN16:
      return bat_cmp_write_bin16_marker(ctx, (uint16_t)obj->as.bin_size);
    case BAT_CMP_TYPE_BIN32:
      return bat_cmp_write_bin32_marker(ctx, obj->as.bin_size);
    case BAT_CMP_TYPE_EXT8:
      return bat_cmp_write_ext8_marker(
        ctx, obj->as.ext.type, (uint8_t)obj->as.ext.size
      );
    case BAT_CMP_TYPE_EXT16:
      return bat_cmp_write_ext16_marker(
        ctx, obj->as.ext.type, (uint16_t)obj->as.ext.size
      );
    case BAT_CMP_TYPE_EXT32:
      return bat_cmp_write_ext32_marker(ctx, obj->as.ext.type, obj->as.ext.size);
    case BAT_CMP_TYPE_FLOAT:
      return bat_cmp_write_float(ctx, obj->as.flt);
    case BAT_CMP_TYPE_DOUBLE:
      return bat_cmp_write_double(ctx, obj->as.dbl);
    case BAT_CMP_TYPE_UINT8:
      return bat_cmp_write_u8(ctx, obj->as.u8);
    case BAT_CMP_TYPE_UINT16:
      return bat_cmp_write_u16(ctx, obj->as.u16);
    case BAT_CMP_TYPE_UINT32:
      return bat_cmp_write_u32(ctx, obj->as.u32);
    case BAT_CMP_TYPE_UINT64:
      return bat_cmp_write_u64(ctx, obj->as.u64);
    case BAT_CMP_TYPE_SINT8:
      return bat_cmp_write_s8(ctx, obj->as.s8);
    case BAT_CMP_TYPE_SINT16:
      return bat_cmp_write_s16(ctx, obj->as.s16);
    case BAT_CMP_TYPE_SINT32:
      return bat_cmp_write_s32(ctx, obj->as.s32);
    case BAT_CMP_TYPE_SINT64:
      return bat_cmp_write_s64(ctx, obj->as.s64);
    case BAT_CMP_TYPE_FIXEXT1:
      return bat_cmp_write_fixext1_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_FIXEXT2:
      return bat_cmp_write_fixext2_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_FIXEXT4:
      return bat_cmp_write_fixext4_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_FIXEXT8:
      return bat_cmp_write_fixext8_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_FIXEXT16:
      return bat_cmp_write_fixext16_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_STR8:
      return bat_cmp_write_str8_marker(ctx, (uint8_t)obj->as.str_size);
    case BAT_CMP_TYPE_STR16:
      return bat_cmp_write_str16_marker(ctx, (uint16_t)obj->as.str_size);
    case BAT_CMP_TYPE_STR32:
      return bat_cmp_write_str32_marker(ctx, obj->as.str_size);
    case BAT_CMP_TYPE_ARRAY16:
      return bat_cmp_write_array16(ctx, (uint16_t)obj->as.array_size);
    case BAT_CMP_TYPE_ARRAY32:
      return bat_cmp_write_array32(ctx, obj->as.array_size);
    case BAT_CMP_TYPE_MAP16:
      return bat_cmp_write_map16(ctx, (uint16_t)obj->as.map_size);
    case BAT_CMP_TYPE_MAP32:
      return bat_cmp_write_map32(ctx, obj->as.map_size);
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
      return bat_cmp_write_nfix(ctx, obj->as.s8);
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_write_object_v4(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj) {
  switch(obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
      return bat_cmp_write_pfix(ctx, obj->as.u8);
    case BAT_CMP_TYPE_FIXMAP:
      return bat_cmp_write_fixmap(ctx, (uint8_t)obj->as.map_size);
    case BAT_CMP_TYPE_FIXARRAY:
      return bat_cmp_write_fixarray(ctx, (uint8_t)obj->as.array_size);
    case BAT_CMP_TYPE_FIXSTR:
      return bat_cmp_write_fixstr_marker(ctx, (uint8_t)obj->as.str_size);
    case BAT_CMP_TYPE_NIL:
      return bat_cmp_write_nil(ctx);
    case BAT_CMP_TYPE_BOOLEAN:
      if (obj->as.boolean)
        return bat_cmp_write_true(ctx);
      return bat_cmp_write_false(ctx);
    case BAT_CMP_TYPE_EXT8:
      return bat_cmp_write_ext8_marker(ctx, obj->as.ext.type, (uint8_t)obj->as.ext.size);
    case BAT_CMP_TYPE_EXT16:
      return bat_cmp_write_ext16_marker(
        ctx, obj->as.ext.type, (uint16_t)obj->as.ext.size
      );
    case BAT_CMP_TYPE_EXT32:
      return bat_cmp_write_ext32_marker(ctx, obj->as.ext.type, obj->as.ext.size);
    case BAT_CMP_TYPE_FLOAT:
      return bat_cmp_write_float(ctx, obj->as.flt);
    case BAT_CMP_TYPE_DOUBLE:
      return bat_cmp_write_double(ctx, obj->as.dbl);
    case BAT_CMP_TYPE_UINT8:
      return bat_cmp_write_u8(ctx, obj->as.u8);
    case BAT_CMP_TYPE_UINT16:
      return bat_cmp_write_u16(ctx, obj->as.u16);
    case BAT_CMP_TYPE_UINT32:
      return bat_cmp_write_u32(ctx, obj->as.u32);
    case BAT_CMP_TYPE_UINT64:
      return bat_cmp_write_u64(ctx, obj->as.u64);
    case BAT_CMP_TYPE_SINT8:
      return bat_cmp_write_s8(ctx, obj->as.s8);
    case BAT_CMP_TYPE_SINT16:
      return bat_cmp_write_s16(ctx, obj->as.s16);
    case BAT_CMP_TYPE_SINT32:
      return bat_cmp_write_s32(ctx, obj->as.s32);
    case BAT_CMP_TYPE_SINT64:
      return bat_cmp_write_s64(ctx, obj->as.s64);
    case BAT_CMP_TYPE_FIXEXT1:
      return bat_cmp_write_fixext1_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_FIXEXT2:
      return bat_cmp_write_fixext2_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_FIXEXT4:
      return bat_cmp_write_fixext4_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_FIXEXT8:
      return bat_cmp_write_fixext8_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_FIXEXT16:
      return bat_cmp_write_fixext16_marker(ctx, obj->as.ext.type);
    case BAT_CMP_TYPE_STR16:
      return bat_cmp_write_str16_marker(ctx, (uint16_t)obj->as.str_size);
    case BAT_CMP_TYPE_STR32:
      return bat_cmp_write_str32_marker(ctx, obj->as.str_size);
    case BAT_CMP_TYPE_ARRAY16:
      return bat_cmp_write_array16(ctx, (uint16_t)obj->as.array_size);
    case BAT_CMP_TYPE_ARRAY32:
      return bat_cmp_write_array32(ctx, obj->as.array_size);
    case BAT_CMP_TYPE_MAP16:
      return bat_cmp_write_map16(ctx, (uint16_t)obj->as.map_size);
    case BAT_CMP_TYPE_MAP32:
      return bat_cmp_write_map32(ctx, obj->as.map_size);
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
      return bat_cmp_write_nfix(ctx, obj->as.s8);
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_read_pfix(bat_cmp_ctx_t *ctx, uint8_t *c) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_POSITIVE_FIXNUM) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *c = obj.as.u8;
  return true;
}

bool bat_cmp_read_nfix(bat_cmp_ctx_t *ctx, int8_t *c) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_NEGATIVE_FIXNUM) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *c = obj.as.s8;
  return true;
}

bool bat_cmp_read_sfix(bat_cmp_ctx_t *ctx, int8_t *c) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
      *c = obj.as.s8;
      return true;
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_read_s8(bat_cmp_ctx_t *ctx, int8_t *c) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_SINT8) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *c = obj.as.s8;
  return true;
}

bool bat_cmp_read_s16(bat_cmp_ctx_t *ctx, int16_t *s) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_SINT16) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *s = obj.as.s16;
  return true;
}

bool bat_cmp_read_s32(bat_cmp_ctx_t *ctx, int32_t *i) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_SINT32) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *i = obj.as.s32;
  return true;
}

bool bat_cmp_read_s64(bat_cmp_ctx_t *ctx, int64_t *l) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_SINT64) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *l = obj.as.s64;
  return true;
}

bool bat_cmp_read_char(bat_cmp_ctx_t *ctx, int8_t *c) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      *c = obj.as.s8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      if (obj.as.u8 <= 127) {
        *c = obj.as.u8;
        return true;
      }
      break;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_short(bat_cmp_ctx_t *ctx, int16_t *s) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      *s = obj.as.s8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      *s = obj.as.u8;
      return true;
    case BAT_CMP_TYPE_SINT16:
      *s = obj.as.s16;
      return true;
    case BAT_CMP_TYPE_UINT16:
      if (obj.as.u16 <= 32767) {
        *s = obj.as.u16;
        return true;
      }
      break;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_int(bat_cmp_ctx_t *ctx, int32_t *i) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      *i = obj.as.s8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      *i = obj.as.u8;
      return true;
    case BAT_CMP_TYPE_SINT16:
      *i = obj.as.s16;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *i = obj.as.u16;
      return true;
    case BAT_CMP_TYPE_SINT32:
      *i = obj.as.s32;
      return true;
    case BAT_CMP_TYPE_UINT32:
      if (obj.as.u32 <= 2147483647) {
        *i = obj.as.u32;
        return true;
      }
      break;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_long(bat_cmp_ctx_t *ctx, int64_t *d) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      *d = obj.as.s8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      *d = obj.as.u8;
      return true;
    case BAT_CMP_TYPE_SINT16:
      *d = obj.as.s16;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *d = obj.as.u16;
      return true;
    case BAT_CMP_TYPE_SINT32:
      *d = obj.as.s32;
      return true;
    case BAT_CMP_TYPE_UINT32:
      *d = obj.as.u32;
      return true;
    case BAT_CMP_TYPE_SINT64:
      *d = obj.as.s64;
      return true;
    case BAT_CMP_TYPE_UINT64:
      if (obj.as.u64 <= 9223372036854775807) {
        *d = obj.as.u64;
        return true;
      }
      break;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_integer(bat_cmp_ctx_t *ctx, int64_t *d) {
  return bat_cmp_read_long(ctx, d);
}

bool bat_cmp_read_ufix(bat_cmp_ctx_t *ctx, uint8_t *c) {
  return bat_cmp_read_pfix(ctx, c);
}

bool bat_cmp_read_u8(bat_cmp_ctx_t *ctx, uint8_t *c) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_UINT8) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *c = obj.as.u8;
  return true;
}

bool bat_cmp_read_u16(bat_cmp_ctx_t *ctx, uint16_t *s) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_UINT16) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *s = obj.as.u16;
  return true;
}

bool bat_cmp_read_u32(bat_cmp_ctx_t *ctx, uint32_t *i) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_UINT32) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *i = obj.as.u32;
  return true;
}

bool bat_cmp_read_u64(bat_cmp_ctx_t *ctx, uint64_t *l) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_UINT64) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *l = obj.as.u64;
  return true;
}

bool bat_cmp_read_uchar(bat_cmp_ctx_t *ctx, uint8_t *c) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      *c = obj.as.u8;
      return true;
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      if (obj.as.s8 >= 0) {
        *c = obj.as.s8;
        return true;
      }
      break;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_ushort(bat_cmp_ctx_t *ctx, uint16_t *s) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      *s = obj.as.u8;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *s = obj.as.u16;
      return true;
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      if (obj.as.s8 >= 0) {
        *s = obj.as.s8;
        return true;
      }
      break;
    case BAT_CMP_TYPE_SINT16:
      if (obj.as.s16 >= 0) {
        *s = obj.as.s16;
        return true;
      }
      break;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_uint(bat_cmp_ctx_t *ctx, uint32_t *i) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      *i = obj.as.u8;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *i = obj.as.u16;
      return true;
    case BAT_CMP_TYPE_UINT32:
      *i = obj.as.u32;
      return true;
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      if (obj.as.s8 >= 0) {
        *i = obj.as.s8;
        return true;
      }
      break;
    case BAT_CMP_TYPE_SINT16:
      if (obj.as.s16 >= 0) {
        *i = obj.as.s16;
        return true;
      }
      break;
    case BAT_CMP_TYPE_SINT32:
      if (obj.as.s32 >= 0) {
        *i = obj.as.s32;
        return true;
      }
      break;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_ulong(bat_cmp_ctx_t *ctx, uint64_t *u) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      *u = obj.as.u8;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *u = obj.as.u16;
      return true;
    case BAT_CMP_TYPE_UINT32:
      *u = obj.as.u32;
      return true;
    case BAT_CMP_TYPE_UINT64:
      *u = obj.as.u64;
      return true;
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      if (obj.as.s8 >= 0) {
        *u = obj.as.s8;
        return true;
      }
      break;
    case BAT_CMP_TYPE_SINT16:
      if (obj.as.s16 >= 0) {
        *u = obj.as.s16;
        return true;
      }
      break;
    case BAT_CMP_TYPE_SINT32:
      if (obj.as.s32 >= 0) {
        *u = obj.as.s32;
        return true;
      }
      break;
    case BAT_CMP_TYPE_SINT64:
      if (obj.as.s64 >= 0) {
        *u = obj.as.s64;
        return true;
      }
      break;
    default:
      break;
  }

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_uinteger(bat_cmp_ctx_t *ctx, uint64_t *d) {
  return bat_cmp_read_ulong(ctx, d);
}

bool bat_cmp_read_float(bat_cmp_ctx_t *ctx, float *f) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_FLOAT) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *f = obj.as.flt;

  return true;
}

bool bat_cmp_read_double(bat_cmp_ctx_t *ctx, double *d) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_DOUBLE) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *d = obj.as.dbl;

  return true;
}

bool bat_cmp_read_decimal(bat_cmp_ctx_t *ctx, double *d) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_FLOAT:
      *d = (double)obj.as.flt;
      return true;
    case BAT_CMP_TYPE_DOUBLE:
      *d = obj.as.dbl;
      return true;
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_read_nil(bat_cmp_ctx_t *ctx) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type == BAT_CMP_TYPE_NIL)
    return true;

  ctx->error = BATCMP_INVALID_TYPE_ERROR;
  return false;
}

bool bat_cmp_read_bool(bat_cmp_ctx_t *ctx, bool *b) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_BOOLEAN) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  if (obj.as.boolean)
    *b = true;
  else
    *b = false;

  return true;
}

bool bat_cmp_read_bool_as_u8(bat_cmp_ctx_t *ctx, uint8_t *b) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_BOOLEAN) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  if (obj.as.boolean)
    *b = 1;
  else
    *b = 0;

  return true;
}

bool bat_cmp_read_str_size(bat_cmp_ctx_t *ctx, uint32_t *size) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_FIXSTR:
    case BAT_CMP_TYPE_STR8:
    case BAT_CMP_TYPE_STR16:
    case BAT_CMP_TYPE_STR32:
      *size = obj.as.str_size;
      return true;
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_read_str(bat_cmp_ctx_t *ctx, char *data, uint32_t *size) {
  uint32_t str_size = 0;

  if (!bat_cmp_read_str_size(ctx, &str_size))
    return false;

  if ((str_size + 1) > *size) {
    *size = str_size;
    ctx->error = BATCMP_STR_DATA_LENGTH_TOO_LONG_ERROR;
    return false;
  }

  if (!ctx->read(ctx, data, str_size)) {
    ctx->error = BATCMP_DATA_READING_ERROR;
    return false;
  }

  data[str_size] = 0;

  *size = str_size;
  return true;
}

bool bat_cmp_read_bin_size(bat_cmp_ctx_t *ctx, uint32_t *size) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_BIN8:
    case BAT_CMP_TYPE_BIN16:
    case BAT_CMP_TYPE_BIN32:
      *size = obj.as.bin_size;
      return true;
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_read_bin(bat_cmp_ctx_t *ctx, void *data, uint32_t *size) {
  uint32_t bin_size = 0;

  if (!bat_cmp_read_bin_size(ctx, &bin_size))
    return false;

  if (bin_size > *size) {
    ctx->error = BATCMP_BIN_DATA_LENGTH_TOO_LONG_ERROR;
    return false;
  }

  if (!ctx->read(ctx, data, bin_size)) {
    ctx->error = BATCMP_DATA_READING_ERROR;
    return false;
  }

  *size = bin_size;
  return true;
}

bool bat_cmp_read_array(bat_cmp_ctx_t *ctx, uint32_t *size) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_FIXARRAY:
    case BAT_CMP_TYPE_ARRAY16:
    case BAT_CMP_TYPE_ARRAY32:
      *size = obj.as.array_size;
      return true;
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_read_map(bat_cmp_ctx_t *ctx, uint32_t *size) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_FIXMAP:
    case BAT_CMP_TYPE_MAP16:
    case BAT_CMP_TYPE_MAP32:
      *size = obj.as.map_size;
      return true;
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_read_fixext1_marker(bat_cmp_ctx_t *ctx, int8_t *type) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;
  
  if (obj.type != BAT_CMP_TYPE_FIXEXT1) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *type = obj.as.ext.type;
  return true;
}

bool bat_cmp_read_fixext1(bat_cmp_ctx_t *ctx, int8_t *type, void *data) {
  if (!bat_cmp_read_fixext1_marker(ctx, type))
    return false;

  if (ctx->read(ctx, data, 1))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_fixext2_marker(bat_cmp_ctx_t *ctx, int8_t *type) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;
  
  if (obj.type != BAT_CMP_TYPE_FIXEXT2) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *type = obj.as.ext.type;
  return true;
}

bool bat_cmp_read_fixext2(bat_cmp_ctx_t *ctx, int8_t *type, void *data) {
  if (!bat_cmp_read_fixext2_marker(ctx, type))
    return false;

  if (ctx->read(ctx, data, 2))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_fixext4_marker(bat_cmp_ctx_t *ctx, int8_t *type) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;
  
  if (obj.type != BAT_CMP_TYPE_FIXEXT4) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *type = obj.as.ext.type;
  return true;
}

bool bat_cmp_read_fixext4(bat_cmp_ctx_t *ctx, int8_t *type, void *data) {
  if (!bat_cmp_read_fixext4_marker(ctx, type))
    return false;

  if (ctx->read(ctx, data, 4))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_fixext8_marker(bat_cmp_ctx_t *ctx, int8_t *type) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;
  
  if (obj.type != BAT_CMP_TYPE_FIXEXT8) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *type = obj.as.ext.type;
  return true;
}

bool bat_cmp_read_fixext8(bat_cmp_ctx_t *ctx, int8_t *type, void *data) {
  if (!bat_cmp_read_fixext8_marker(ctx, type))
    return false;

  if (ctx->read(ctx, data, 8))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_fixext16_marker(bat_cmp_ctx_t *ctx, int8_t *type) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;
  
  if (obj.type != BAT_CMP_TYPE_FIXEXT16) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *type = obj.as.ext.type;
  return true;
}

bool bat_cmp_read_fixext16(bat_cmp_ctx_t *ctx, int8_t *type, void *data) {
  if (!bat_cmp_read_fixext16_marker(ctx, type))
    return false;

  if (ctx->read(ctx, data, 16))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_ext8_marker(bat_cmp_ctx_t *ctx, int8_t *type, uint8_t *size) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_EXT8) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *type = obj.as.ext.type;
  *size = (uint8_t)obj.as.ext.size;

  return true;
}

bool bat_cmp_read_ext8(bat_cmp_ctx_t *ctx, int8_t *type, uint8_t *size, void *data) {
  if (!bat_cmp_read_ext8_marker(ctx, type, size))
    return false;

  if (ctx->read(ctx, data, *size))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_ext16_marker(bat_cmp_ctx_t *ctx, int8_t *type, uint16_t *size) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_EXT16) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *type = obj.as.ext.type;
  *size = (uint16_t)obj.as.ext.size;

  return true;
}

bool bat_cmp_read_ext16(bat_cmp_ctx_t *ctx, int8_t *type, uint16_t *size, void *data) {
  if (!bat_cmp_read_ext16_marker(ctx, type, size))
    return false;

  if (ctx->read(ctx, data, *size))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_ext32_marker(bat_cmp_ctx_t *ctx, int8_t *type, uint32_t *size) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  if (obj.type != BAT_CMP_TYPE_EXT32) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  *type = obj.as.ext.type;
  *size = obj.as.ext.size;

  return true;
}

bool bat_cmp_read_ext32(bat_cmp_ctx_t *ctx, int8_t *type, uint32_t *size, void *data) {
  if (!bat_cmp_read_ext32_marker(ctx, type, size))
    return false;

  if (ctx->read(ctx, data, *size))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_ext_marker(bat_cmp_ctx_t *ctx, int8_t *type, uint32_t *size) {
  bat_cmp_object_t obj;

  if (!bat_cmp_read_object(ctx, &obj))
    return false;

  switch (obj.type) {
    case BAT_CMP_TYPE_FIXEXT1:
    case BAT_CMP_TYPE_FIXEXT2:
    case BAT_CMP_TYPE_FIXEXT4:
    case BAT_CMP_TYPE_FIXEXT8:
    case BAT_CMP_TYPE_FIXEXT16:
    case BAT_CMP_TYPE_EXT8:
    case BAT_CMP_TYPE_EXT16:
    case BAT_CMP_TYPE_EXT32:
      *type = obj.as.ext.type;
      *size = obj.as.ext.size;
      return true;
    default:
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
  }
}

bool bat_cmp_read_ext(bat_cmp_ctx_t *ctx, int8_t *type, uint32_t *size, void *data) {
  if (!bat_cmp_read_ext_marker(ctx, type, size))
    return false;

  if (ctx->read(ctx, data, *size))
    return true;

  ctx->error = BATCMP_DATA_READING_ERROR;
  return false;
}

bool bat_cmp_read_object(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj) {
  uint8_t type_marker = 0;

  if (!read_type_marker(ctx, &type_marker))
    return false;

  if (!type_marker_to_bat_cmp_type(type_marker, &obj->type)) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  return read_obj_data(ctx, type_marker, obj);
}

bool bat_cmp_skip_object(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj) {
  uint8_t type_marker = 0;
  uint8_t bat_cmp_type;
  uint32_t size = 0;

  if (!read_type_marker(ctx, &type_marker)) {
    return false;
  }

  if (!type_marker_to_bat_cmp_type(type_marker, &bat_cmp_type)) {
    ctx->error = BATCMP_INVALID_TYPE_ERROR;
    return false;
  }

  switch (bat_cmp_type) {
    case BAT_CMP_TYPE_FIXARRAY:
    case BAT_CMP_TYPE_ARRAY16:
    case BAT_CMP_TYPE_ARRAY32:
    case BAT_CMP_TYPE_FIXMAP:
    case BAT_CMP_TYPE_MAP16:
    case BAT_CMP_TYPE_MAP32:
      obj->type = bat_cmp_type;

      if (!read_obj_data(ctx, type_marker, obj)) {
        return false;
      }

      ctx->error = BATCMP_SKIP_DEPTH_LIMIT_EXCEEDED_ERROR;

      return false;
    default:
      if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
        return false;
      }

      if (size) {
        switch (bat_cmp_type) {
          case BAT_CMP_TYPE_FIXEXT1:
          case BAT_CMP_TYPE_FIXEXT2:
          case BAT_CMP_TYPE_FIXEXT4:
          case BAT_CMP_TYPE_FIXEXT8:
          case BAT_CMP_TYPE_FIXEXT16:
          case BAT_CMP_TYPE_EXT8:
          case BAT_CMP_TYPE_EXT16:
          case BAT_CMP_TYPE_EXT32:
            size++;
          default:
            break;
        }

        skip_bytes(ctx, size);
      }
  }

  return true;
}

bool bat_cmp_skip_object_flat(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj) {
  size_t element_count = 1;
  bool in_container = false;

  while (element_count) {
    uint8_t type_marker = 0;
    uint8_t bat_cmp_type;
    uint32_t size = 0;

    if (!read_type_marker(ctx, &type_marker)) {
      return false;
    }

    if (!type_marker_to_bat_cmp_type(type_marker, &bat_cmp_type)) {
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
    }

    switch (bat_cmp_type) {
      case BAT_CMP_TYPE_FIXARRAY:
      case BAT_CMP_TYPE_ARRAY16:
      case BAT_CMP_TYPE_ARRAY32:
      case BAT_CMP_TYPE_FIXMAP:
      case BAT_CMP_TYPE_MAP16:
      case BAT_CMP_TYPE_MAP32:
        if (in_container) {
          obj->type = bat_cmp_type;

          if (!read_obj_data(ctx, type_marker, obj)) {
            return false;
          }

          ctx->error = BATCMP_SKIP_DEPTH_LIMIT_EXCEEDED_ERROR;
          return false;
        }

        in_container = true;

        break;
      default:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }

        if (size) {
          switch (bat_cmp_type) {
            case BAT_CMP_TYPE_FIXEXT1:
            case BAT_CMP_TYPE_FIXEXT2:
            case BAT_CMP_TYPE_FIXEXT4:
            case BAT_CMP_TYPE_FIXEXT8:
            case BAT_CMP_TYPE_FIXEXT16:
            case BAT_CMP_TYPE_EXT8:
            case BAT_CMP_TYPE_EXT16:
            case BAT_CMP_TYPE_EXT32:
              size++;
            default:
              break;
          }

          skip_bytes(ctx, size);
        }
    }

    element_count--;

    switch (bat_cmp_type) {
      case BAT_CMP_TYPE_FIXARRAY:
      case BAT_CMP_TYPE_ARRAY16:
      case BAT_CMP_TYPE_ARRAY32:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }
        element_count += size;
        break;
      case BAT_CMP_TYPE_FIXMAP:
      case BAT_CMP_TYPE_MAP16:
      case BAT_CMP_TYPE_MAP32:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }
        element_count += ((size_t)size) * 2;
        break;
      default:
        break;
    }
  }

  return true;
}

bool bat_cmp_skip_object_no_limit(bat_cmp_ctx_t *ctx) {
  size_t element_count = 1;

  while (element_count) {
    uint8_t type_marker = 0;
    uint8_t bat_cmp_type = 0;
    uint32_t size = 0;

    if (!read_type_marker(ctx, &type_marker)) {
      return false;
    }

    if (!type_marker_to_bat_cmp_type(type_marker, &bat_cmp_type)) {
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
    }

    switch (bat_cmp_type) {
      case BAT_CMP_TYPE_FIXARRAY:
      case BAT_CMP_TYPE_ARRAY16:
      case BAT_CMP_TYPE_ARRAY32:
      case BAT_CMP_TYPE_FIXMAP:
      case BAT_CMP_TYPE_MAP16:
      case BAT_CMP_TYPE_MAP32:
        break;
      default:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }

        if (size) {
          switch (bat_cmp_type) {
            case BAT_CMP_TYPE_FIXEXT1:
            case BAT_CMP_TYPE_FIXEXT2:
            case BAT_CMP_TYPE_FIXEXT4:
            case BAT_CMP_TYPE_FIXEXT8:
            case BAT_CMP_TYPE_FIXEXT16:
            case BAT_CMP_TYPE_EXT8:
            case BAT_CMP_TYPE_EXT16:
            case BAT_CMP_TYPE_EXT32:
              size++;
            default:
              break;
          }

          skip_bytes(ctx, size);
        }
    }

    element_count--;

    switch (bat_cmp_type) {
      case BAT_CMP_TYPE_FIXARRAY:
      case BAT_CMP_TYPE_ARRAY16:
      case BAT_CMP_TYPE_ARRAY32:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }
        element_count += size;
        break;
      case BAT_CMP_TYPE_FIXMAP:
      case BAT_CMP_TYPE_MAP16:
      case BAT_CMP_TYPE_MAP32:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }
        element_count += ((size_t)size) * 2;
        break;
      default:
        break;
    }
  }

  return true;
}

bool bat_cmp_skip_object_limit(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj, uint32_t limit) {
  size_t element_count = 1;
  uint32_t depth = 0;

  while (element_count) {
    uint8_t type_marker = 0;
    uint8_t bat_cmp_type;
    uint32_t size = 0;

    if (!read_type_marker(ctx, &type_marker)) {
      return false;
    }

    if (!type_marker_to_bat_cmp_type(type_marker, &bat_cmp_type)) {
      ctx->error = BATCMP_INVALID_TYPE_ERROR;
      return false;
    }

    switch (bat_cmp_type) {
      case BAT_CMP_TYPE_FIXARRAY:
      case BAT_CMP_TYPE_ARRAY16:
      case BAT_CMP_TYPE_ARRAY32:
      case BAT_CMP_TYPE_FIXMAP:
      case BAT_CMP_TYPE_MAP16:
      case BAT_CMP_TYPE_MAP32:
        depth++;

        if (depth > limit) {
          obj->type = bat_cmp_type;

          if (!read_obj_data(ctx, type_marker, obj)) {
            return false;
          }

          ctx->error = BATCMP_SKIP_DEPTH_LIMIT_EXCEEDED_ERROR;

          return false;
        }

        break;
      default:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }

        if (size) {
          switch (bat_cmp_type) {
            case BAT_CMP_TYPE_FIXEXT1:
            case BAT_CMP_TYPE_FIXEXT2:
            case BAT_CMP_TYPE_FIXEXT4:
            case BAT_CMP_TYPE_FIXEXT8:
            case BAT_CMP_TYPE_FIXEXT16:
            case BAT_CMP_TYPE_EXT8:
            case BAT_CMP_TYPE_EXT16:
            case BAT_CMP_TYPE_EXT32:
              size++;
            default:
              break;
          }

          skip_bytes(ctx, size);
        }
    }

    element_count--;

    switch (bat_cmp_type) {
      case BAT_CMP_TYPE_FIXARRAY:
      case BAT_CMP_TYPE_ARRAY16:
      case BAT_CMP_TYPE_ARRAY32:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }
        element_count += size;
        break;
      case BAT_CMP_TYPE_FIXMAP:
      case BAT_CMP_TYPE_MAP16:
      case BAT_CMP_TYPE_MAP32:
        if (!read_type_size(ctx, type_marker, bat_cmp_type, &size)) {
          return false;
        }
        element_count += ((size_t)size) * 2;
        break;
      default:
        break;
    }
  }

  return true;
}

bool bat_cmp_object_is_char(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_short(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
    case BAT_CMP_TYPE_SINT16:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_int(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
    case BAT_CMP_TYPE_SINT16:
    case BAT_CMP_TYPE_SINT32:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_long(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
    case BAT_CMP_TYPE_SINT16:
    case BAT_CMP_TYPE_SINT32:
    case BAT_CMP_TYPE_SINT64:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_sinteger(bat_cmp_object_t *obj) {
  return bat_cmp_object_is_long(obj);
}

bool bat_cmp_object_is_uchar(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_ushort(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      return true;
    case BAT_CMP_TYPE_UINT16:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_uint(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
    case BAT_CMP_TYPE_UINT16:
    case BAT_CMP_TYPE_UINT32:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_ulong(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
    case BAT_CMP_TYPE_UINT16:
    case BAT_CMP_TYPE_UINT32:
    case BAT_CMP_TYPE_UINT64:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_uinteger(bat_cmp_object_t *obj) {
  return bat_cmp_object_is_ulong(obj);
}

bool bat_cmp_object_is_float(bat_cmp_object_t *obj) {
  if (obj->type == BAT_CMP_TYPE_FLOAT)
    return true;

  return false;
}

bool bat_cmp_object_is_double(bat_cmp_object_t *obj) {
  if (obj->type == BAT_CMP_TYPE_DOUBLE)
    return true;

  return false;
}

bool bat_cmp_object_is_nil(bat_cmp_object_t *obj) {
  if (obj->type == BAT_CMP_TYPE_NIL)
    return true;

  return false;
}

bool bat_cmp_object_is_bool(bat_cmp_object_t *obj) {
  if (obj->type == BAT_CMP_TYPE_BOOLEAN)
    return true;

  return false;
}

bool bat_cmp_object_is_str(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_FIXSTR:
    case BAT_CMP_TYPE_STR8:
    case BAT_CMP_TYPE_STR16:
    case BAT_CMP_TYPE_STR32:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_bin(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_BIN8:
    case BAT_CMP_TYPE_BIN16:
    case BAT_CMP_TYPE_BIN32:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_array(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_FIXARRAY:
    case BAT_CMP_TYPE_ARRAY16:
    case BAT_CMP_TYPE_ARRAY32:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_map(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_FIXMAP:
    case BAT_CMP_TYPE_MAP16:
    case BAT_CMP_TYPE_MAP32:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_is_ext(bat_cmp_object_t *obj) {
  switch (obj->type) {
    case BAT_CMP_TYPE_FIXEXT1:
    case BAT_CMP_TYPE_FIXEXT2:
    case BAT_CMP_TYPE_FIXEXT4:
    case BAT_CMP_TYPE_FIXEXT8:
    case BAT_CMP_TYPE_FIXEXT16:
    case BAT_CMP_TYPE_EXT8:
    case BAT_CMP_TYPE_EXT16:
    case BAT_CMP_TYPE_EXT32:
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_as_char(bat_cmp_object_t *obj, int8_t *c) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      *c = obj->as.s8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      if (obj->as.u8 <= 127) {
        *c = obj->as.s8;
        return true;
      }
      else {
        return false;
      }
    default:
        return false;
  }
}

bool bat_cmp_object_as_short(bat_cmp_object_t *obj, int16_t *s) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      *s = obj->as.s8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      *s = obj->as.u8;
      return true;
    case BAT_CMP_TYPE_SINT16:
      *s = obj->as.s16;
      return true;
    case BAT_CMP_TYPE_UINT16:
      if (obj->as.u16 <= 32767) {
        *s = obj->as.u16;
        return true;
      }
      else {
        return false;
      }
    default:
        return false;
  }
}

bool bat_cmp_object_as_int(bat_cmp_object_t *obj, int32_t *i) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      *i = obj->as.s8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      *i = obj->as.u8;
      return true;
    case BAT_CMP_TYPE_SINT16:
      *i = obj->as.s16;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *i = obj->as.u16;
      return true;
    case BAT_CMP_TYPE_SINT32:
      *i = obj->as.s32;
      return true;
    case BAT_CMP_TYPE_UINT32:
      if (obj->as.u32 <= 2147483647) {
        *i = obj->as.u32;
        return true;
      }
      else {
        return false;
      }
    default:
        return false;
  }
}

bool bat_cmp_object_as_long(bat_cmp_object_t *obj, int64_t *d) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
    case BAT_CMP_TYPE_SINT8:
      *d = obj->as.s8;
      return true;
    case BAT_CMP_TYPE_UINT8:
      *d = obj->as.u8;
      return true;
    case BAT_CMP_TYPE_SINT16:
      *d = obj->as.s16;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *d = obj->as.u16;
      return true;
    case BAT_CMP_TYPE_SINT32:
      *d = obj->as.s32;
      return true;
    case BAT_CMP_TYPE_UINT32:
      *d = obj->as.u32;
      return true;
    case BAT_CMP_TYPE_SINT64:
      *d = obj->as.s64;
      return true;
    case BAT_CMP_TYPE_UINT64:
      if (obj->as.u64 <= 9223372036854775807) {
        *d = obj->as.u64;
        return true;
      }
      else {
        return false;
      }
    default:
        return false;
  }
}

bool bat_cmp_object_as_sinteger(bat_cmp_object_t *obj, int64_t *d) {
  return bat_cmp_object_as_long(obj, d);
}

bool bat_cmp_object_as_uchar(bat_cmp_object_t *obj, uint8_t *c) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      *c = obj->as.u8;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_as_ushort(bat_cmp_object_t *obj, uint16_t *s) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      *s = obj->as.u8;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *s = obj->as.u16;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_as_uint(bat_cmp_object_t *obj, uint32_t *i) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      *i = obj->as.u8;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *i = obj->as.u16;
      return true;
    case BAT_CMP_TYPE_UINT32:
      *i = obj->as.u32;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_as_ulong(bat_cmp_object_t *obj, uint64_t *u) {
  switch (obj->type) {
    case BAT_CMP_TYPE_POSITIVE_FIXNUM:
    case BAT_CMP_TYPE_UINT8:
      *u = obj->as.u8;
      return true;
    case BAT_CMP_TYPE_UINT16:
      *u = obj->as.u16;
      return true;
    case BAT_CMP_TYPE_UINT32:
      *u = obj->as.u32;
      return true;
    case BAT_CMP_TYPE_UINT64:
      *u = obj->as.u64;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_as_uinteger(bat_cmp_object_t *obj, uint64_t *d) {
  return bat_cmp_object_as_ulong(obj, d);
}

bool bat_cmp_object_as_float(bat_cmp_object_t *obj, float *f) {
  if (obj->type == BAT_CMP_TYPE_FLOAT) {
    *f = obj->as.flt;
    return true;
  }

  return false;
}

bool bat_cmp_object_as_double(bat_cmp_object_t *obj, double *d) {
  if (obj->type == BAT_CMP_TYPE_DOUBLE) {
    *d = obj->as.dbl;
    return true;
  }

  return false;
}

bool bat_cmp_object_as_bool(bat_cmp_object_t *obj, bool *b) {
  if (obj->type == BAT_CMP_TYPE_BOOLEAN) {
    if (obj->as.boolean)
      *b = true;
    else
      *b = false;

    return true;
  }

  return false;
}

bool bat_cmp_object_as_str(bat_cmp_object_t *obj, uint32_t *size) {
  switch (obj->type) {
    case BAT_CMP_TYPE_FIXSTR:
    case BAT_CMP_TYPE_STR8:
    case BAT_CMP_TYPE_STR16:
    case BAT_CMP_TYPE_STR32:
      *size = obj->as.str_size;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_as_bin(bat_cmp_object_t *obj, uint32_t *size) {
  switch (obj->type) {
    case BAT_CMP_TYPE_BIN8:
    case BAT_CMP_TYPE_BIN16:
    case BAT_CMP_TYPE_BIN32:
      *size = obj->as.bin_size;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_as_array(bat_cmp_object_t *obj, uint32_t *size) {
  switch (obj->type) {
    case BAT_CMP_TYPE_FIXARRAY:
    case BAT_CMP_TYPE_ARRAY16:
    case BAT_CMP_TYPE_ARRAY32:
      *size = obj->as.array_size;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_as_map(bat_cmp_object_t *obj, uint32_t *size) {
  switch (obj->type) {
    case BAT_CMP_TYPE_FIXMAP:
    case BAT_CMP_TYPE_MAP16:
    case BAT_CMP_TYPE_MAP32:
      *size = obj->as.map_size;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_as_ext(bat_cmp_object_t *obj, int8_t *type, uint32_t *size) {
  switch (obj->type) {
    case BAT_CMP_TYPE_FIXEXT1:
    case BAT_CMP_TYPE_FIXEXT2:
    case BAT_CMP_TYPE_FIXEXT4:
    case BAT_CMP_TYPE_FIXEXT8:
    case BAT_CMP_TYPE_FIXEXT16:
    case BAT_CMP_TYPE_EXT8:
    case BAT_CMP_TYPE_EXT16:
    case BAT_CMP_TYPE_EXT32:
      *type = obj->as.ext.type;
      *size = obj->as.ext.size;
      return true;
    default:
        return false;
  }
}

bool bat_cmp_object_to_str(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj, char *data,
                                                          uint32_t buf_size) {
  uint32_t str_size = 0;

  switch (obj->type) {
    case BAT_CMP_TYPE_FIXSTR:
    case BAT_CMP_TYPE_STR8:
    case BAT_CMP_TYPE_STR16:
    case BAT_CMP_TYPE_STR32:
      str_size = obj->as.str_size;
      if ((str_size + 1) > buf_size) {
        ctx->error = BATCMP_STR_DATA_LENGTH_TOO_LONG_ERROR;
        return false;
      }

      if (!ctx->read(ctx, data, str_size)) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }

      data[str_size] = 0;
      return true;
    default:
      return false;
  }
}

bool bat_cmp_object_to_bin(bat_cmp_ctx_t *ctx, bat_cmp_object_t *obj, void *data,
                                                          uint32_t buf_size) {
  uint32_t bin_size = 0;

  switch (obj->type) {
    case BAT_CMP_TYPE_BIN8:
    case BAT_CMP_TYPE_BIN16:
    case BAT_CMP_TYPE_BIN32:
      bin_size = obj->as.bin_size;
      if (bin_size > buf_size) {
        ctx->error = BATCMP_BIN_DATA_LENGTH_TOO_LONG_ERROR;
        return false;
      }

      if (!ctx->read(ctx, data, bin_size)) {
        ctx->error = BATCMP_DATA_READING_ERROR;
        return false;
      }
      return true;
    default:
      return false;
  }
}

/* vi: set et ts=2 sw=2: */

